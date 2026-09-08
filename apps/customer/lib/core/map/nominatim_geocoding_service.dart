import 'package:dio/dio.dart';

/// Один результат поиска адреса.
class GeoSearchResult {
  const GeoSearchResult({required this.lat, required this.lng, required this.label});

  final double lat;
  final double lng;
  final String label;
}

/// Геокодирование через Nominatim (OpenStreetMap) — бесплатно, без ключей.
///
/// Это публичный сервис с политикой использования (~1 запрос/сек, обязателен
/// узнаваемый User-Agent) — годится для разработки и небольшой нагрузки, но
/// не для продакшена с реальным трафиком: тогда нужен платный геокодер
/// (Яндекс.Геокодер и т.п.) либо самостоятельно поднятый Nominatim.
class NominatimGeocodingService {
  NominatimGeocodingService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          headers: {'User-Agent': 'SilkwayApp/1.0'},
        ));

  final Dio _dio;

  Future<List<GeoSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {
        'format': 'json',
        'q': query,
        'limit': 5,
        'accept-language': 'ru',
        // Смещаем выдачу к Москве, не ограничивая её жёстко — на случай,
        // если ресторан когда-нибудь появится в другом городе.
        'viewbox': '36.8,56.0,38.3,55.3',
        'bounded': 0,
      },
    );
    return (res.data ?? [])
        .map((raw) {
          final json = raw as Map<String, dynamic>;
          return GeoSearchResult(
            lat: double.parse(json['lat'] as String),
            lng: double.parse(json['lon'] as String),
            label: json['display_name'] as String,
          );
        })
        .toList();
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: {'format': 'json', 'lat': lat, 'lon': lng, 'accept-language': 'ru'},
    );
    return res.data?['display_name'] as String?;
  }
}
