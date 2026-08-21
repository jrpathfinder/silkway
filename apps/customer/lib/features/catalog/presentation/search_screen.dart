import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_bottom_sheet.dart';
import '../../../core/design_system/widgets/sw_dish_card.dart';
import '../../../core/design_system/widgets/sw_empty_state.dart';
import '../../../core/design_system/widgets/sw_search_field.dart';
import '../../../core/design_system/widgets/sw_section_header.dart';
import '../../../core/models/catalog.dart';
import '../../../core/providers.dart';
import '../../locations/presentation/providers/locations_providers.dart';
import 'item_detail_sheet.dart';
import 'providers/catalog_providers.dart';

/// Поиск по меню.
///
/// Фильтрация идёт **на клиенте**, по уже загруженному каталогу: поискового
/// эндпоинта на бэкенде нет, а меню одного филиала целиком помещается в
/// памяти. Поэтому результаты появляются мгновенно, без сети и без индикатора
/// загрузки.
///
/// Если каталог когда-нибудь вырастет настолько, что клиентский поиск начнёт
/// тормозить, менять придётся только этот файл — экранам он отдаёт готовый
/// результат.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  /// Ключ хранения недавних запросов. Лежит в обычном LocalKv, не в
  /// защищённом: это не секрет.
  static const recentKey = 'search_recent';
  static const maxRecent = 6;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final raw = await ref.read(localKvProvider).getString(SearchScreen.recentKey);
    if (!mounted || raw == null || raw.isEmpty) return;
    setState(() => _recent = raw.split('\n').where((s) => s.isNotEmpty).toList());
  }

  Future<void> _remember(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    // Дубликат поднимаем наверх, а не добавляем второй раз.
    final next = [trimmed, ..._recent.where((q) => q.toLowerCase() != trimmed.toLowerCase())]
        .take(SearchScreen.maxRecent)
        .toList();
    setState(() => _recent = next);
    await ref.read(localKvProvider).setString(SearchScreen.recentKey, next.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locationId = ref.watch(selectedLocationIdProvider);
    final query = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: SwSpacing.screenH),
          child: SwSearchField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(_controller.clear),
            // Запоминаем по факту отправки, а не на каждое нажатие клавиши:
            // иначе в недавних окажутся обрывки вроде «пло».
            onSubmitted: _remember,
          ),
        ),
      ),
      body: locationId == null
          ? const SwEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Филиал не выбран',
              message: 'Выберите филиал на главном экране, чтобы искать по его меню.',
            )
          : ref.watch(catalogProvider(locationId)).when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SwEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Поиск недоступен',
                  message: 'Меню не загрузилось. Вернитесь на главный и попробуйте ещё раз.',
                ),
                data: (catalog) => query.isEmpty
                    ? _Recent(
                        queries: _recent,
                        onPick: (q) {
                          _controller.text = q;
                          setState(() {});
                        },
                      )
                    : _Results(
                        catalog: catalog,
                        query: query,
                        locationId: locationId,
                        scheme: scheme,
                      ),
              ),
    );
  }
}

/// Недавние запросы — показываются, пока поле пустое.
class _Recent extends StatelessWidget {
  const _Recent({required this.queries, required this.onPick});

  final List<String> queries;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return const SwEmptyState(
        icon: Icons.search_rounded,
        title: 'Что ищем?',
        message: 'Введите название блюда — например, плов или самса.',
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SwSectionHeader(title: 'Вы искали'),
        for (final q in queries)
          ListTile(
            leading: Icon(Icons.history_rounded, color: scheme.onSurfaceVariant),
            title: Text(q, style: SwTypography.body.copyWith(color: scheme.onSurface)),
            onTap: () => onPick(q),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.catalog,
    required this.query,
    required this.locationId,
    required this.scheme,
  });

  final CatalogResponse catalog;
  final String query;
  final String locationId;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final dishes = catalog.availableItems
        .where((i) => i.name.toLowerCase().contains(q) || i.description.toLowerCase().contains(q))
        .toList();
    final categories = catalog.categories.where((c) => c.name.toLowerCase().contains(q)).toList();

    if (dishes.isEmpty && categories.isEmpty) {
      return SwEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Ничего не нашлось',
        message: 'По запросу «$query» блюд нет. Попробуйте другое название.',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: SwSpacing.xxxl),
      children: [
        if (categories.isNotEmpty) ...[
          const SwSectionHeader(title: 'Категории'),
          for (final c in categories)
            ListTile(
              leading: Icon(Icons.category_outlined, color: scheme.onSurfaceVariant),
              title: Text(c.name, style: SwTypography.body.copyWith(color: scheme.onSurface)),
              subtitle: Text(
                '${catalog.availableItems.where((i) => i.categoryId == c.id).length} блюд',
                style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
        if (dishes.isNotEmpty) ...[
          const SwSectionHeader(title: 'Блюда'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SwSpacing.screenH),
            child: Column(
              children: [
                for (final item in dishes) ...[
                  SwDishCard(
                    item: item,
                    onTap: () => showSwBottomSheet(
                      context,
                      builder: (context) => ItemDetailSheet(item: item, locationId: locationId),
                    ),
                  ),
                  const SizedBox(height: SwSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
