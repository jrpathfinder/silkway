import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/network/api_client.dart';
import 'package:silkway_app/features/locations/data/locations_repository_http.dart';

import '../helpers/fakes.dart';

void main() {
  test('listActive GETs /v1/locations and maps each item', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/locations');
      return (
        200,
        '{"data": [{"id": "ca-moscow-1", "cityId": "moscow", "name": "N", "address": "A", "timezone": "Europe/Moscow", "isActive": true}]}',
      );
    });

    final repo = LocationsRepositoryHttp(client);
    final locations = await repo.listActive();

    expect(locations, hasLength(1));
    expect(locations.single.id, 'ca-moscow-1');
  });

  test('getById returns the location when found', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/locations/ca-moscow-1');
      return (
        200,
        '{"data": {"id": "ca-moscow-1", "cityId": "moscow", "name": "N", "address": "A", "timezone": "Europe/Moscow", "isActive": true}}',
      );
    });

    final repo = LocationsRepositoryHttp(client);
    final location = await repo.getById('ca-moscow-1');

    expect(location?.id, 'ca-moscow-1');
  });

  test('getById returns null when the backend returns no data', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) => (200, '{"data": null}'));

    final repo = LocationsRepositoryHttp(client);
    final location = await repo.getById('missing');

    expect(location, isNull);
  });
}
