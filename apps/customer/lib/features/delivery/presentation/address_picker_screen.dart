import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/map/nominatim_geocoding_service.dart';
import '../../../core/models/delivery.dart';
import '../../../core/models/delivery_zone.dart';
import '../../../core/providers.dart';

const _defaultCenter = LatLng(55.751244, 37.618423);

/// Выбор адреса доставки на карте — референс Uber Eats/Wolt/Яндекс Еды:
/// булавка закреплена по центру экрана, двигается карта, а не булавка;
/// адрес под ней обновляется обратным геокодированием после остановки.
///
/// Возвращает [DeliveryAddress] через `Navigator.pop`, либо `null` при отмене.
class AddressPickerScreen extends ConsumerStatefulWidget {
  const AddressPickerScreen({super.key, this.initial});

  final DeliveryAddress? initial;

  @override
  ConsumerState<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends ConsumerState<AddressPickerScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _commentController = TextEditingController();

  Timer? _reverseGeocodeDebounce;
  Timer? _searchDebounce;
  List<GeoSearchResult> _searchResults = [];
  String? _addressText;
  bool _loadingAddress = false;
  bool _locating = false;
  bool _outOfZone = false;

  LatLng get _initialCenter =>
      widget.initial != null ? LatLng(widget.initial!.lat, widget.initial!.lng) : _defaultCenter;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.initial?.comment ?? '';
    _addressText = widget.initial?.addressText;
    _outOfZone = !MoscowDeliveryZone.contains(_initialCenter.latitude, _initialCenter.longitude);
    if (_addressText == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reverseGeocodeNow(_initialCenter));
    }
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocodeNow(LatLng point) async {
    setState(() => _loadingAddress = true);
    try {
      final label = await ref.read(geocodingServiceProvider).reverseGeocode(point.latitude, point.longitude);
      if (mounted) setState(() => _addressText = label ?? _addressText);
    } catch (_) {
      // Тихо: адрес под булавкой просто не обновится, кнопка подтверждения
      // остаётся доступна с последним известным значением.
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _onCameraMove(MapCamera camera, bool hasGesture) {
    // Зона доставки — чистая геометрия, без сети: проверяем сразу на каждое
    // движение карты, а не ждём дебаунса геокодирования — булавка должна
    // измениться в тот же момент, когда центр вышел за пределы зоны.
    final outOfZone = !MoscowDeliveryZone.contains(camera.center.latitude, camera.center.longitude);
    if (outOfZone != _outOfZone) setState(() => _outOfZone = outOfZone);

    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 600), () => _reverseGeocodeNow(camera.center));
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await ref.read(geocodingServiceProvider).search(query);
        if (mounted) setState(() => _searchResults = results);
      } catch (_) {
        // Поиск просто не покажет результатов — не критично для UX.
      }
    });
  }

  void _selectSearchResult(GeoSearchResult result) {
    _mapController.move(LatLng(result.lat, result.lng), 16);
    setState(() {
      _searchResults = [];
      _addressText = result.label;
      _searchController.text = result.label;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final point = await ref.read(mapProviderProvider).currentLocation();
      _mapController.move(LatLng(point.lat, point.lng), 16);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    if (_outOfZone) return;
    final center = _mapController.camera.center;
    Navigator.of(context).pop(
      DeliveryAddress(
        lat: center.latitude,
        lng: center.longitude,
        addressText: _addressText ?? 'Точка на карте',
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 16,
              onPositionChanged: _onCameraMove,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'net.nomiq.silkway',
              ),
              // Границу зоны рисуем прямо на карте — раньше о ней можно было
              // узнать только реакцией пина постфактум, когда уже уехал за
              // край. Подсвечиваем саму зону (как Wolt/Uber Eats подсвечивают
              // зону обслуживания), а не то, что снаружи неё.
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: const [
                      LatLng(MoscowDeliveryZone.minLat, MoscowDeliveryZone.minLng),
                      LatLng(MoscowDeliveryZone.minLat, MoscowDeliveryZone.maxLng),
                      LatLng(MoscowDeliveryZone.maxLat, MoscowDeliveryZone.maxLng),
                      LatLng(MoscowDeliveryZone.maxLat, MoscowDeliveryZone.minLng),
                    ],
                    color: scheme.primary.withValues(alpha: 0.06),
                    borderStrokeWidth: 2,
                    borderColor: scheme.primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),

          // Булавка нарисована поверх карты и не двигается — едет сама карта.
          // Сдвиг вверх на половину высоты иконки, чтобы остриё указывало
          // ровно в центр, а не сама иконка. Цвет меняется на "ошибку" сразу
          // при выходе за зону доставки, без ожидания геокодирования.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(
                  _outOfZone ? Icons.location_off : Icons.location_on,
                  size: 44,
                  color: _outOfZone ? scheme.error : scheme.primary,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(SwSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundIconButton(icon: Icons.close, onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: SwSpacing.sm),
                      Expanded(
                        child: Material(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
                          elevation: 2,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Улица, дом',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: SwSpacing.sm),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final result in _searchResults)
                            ListTile(
                              leading: const Icon(Icons.place_outlined),
                              title: Text(result.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () => _selectSearchResult(result),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            right: SwSpacing.lg,
            bottom: 260,
            child: _RoundIconButton(icon: Icons.my_location, onTap: _locating ? null : _useCurrentLocation, loading: _locating),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(SwSpacing.lg),
                padding: const EdgeInsets.all(SwSpacing.lg),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(SwSpacing.radiusXl),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _outOfZone ? Icons.block : Icons.location_on,
                          color: _outOfZone ? scheme.error : scheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: SwSpacing.sm),
                        Expanded(
                          child: _outOfZone
                              ? Text(
                                  'Мы не доставляем в этот район. Попробуйте другой адрес в Москве.',
                                  style: SwTypography.bodyStrong.copyWith(color: scheme.error),
                                )
                              : _loadingAddress
                                  ? Text('Определяем адрес…', style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant))
                                  : Text(
                                      _addressText ?? 'Переместите карту, чтобы выбрать адрес',
                                      style: SwTypography.bodyStrong.copyWith(color: scheme.onSurface),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                        ),
                      ],
                    ),
                    if (!_outOfZone) ...[
                      const SizedBox(height: SwSpacing.md),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Комментарий курьеру: домофон, этаж (необязательно)',
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(SwSpacing.radiusMd), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: SwSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _outOfZone || _addressText == null || _loadingAddress ? null : _confirm,
                        child: const Text('Подтвердить адрес'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.loading = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: SwSpacing.minTapTarget,
          height: SwSpacing.minTapTarget,
          child: loading
              ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, color: scheme.onSurface),
        ),
      ),
    );
  }
}
