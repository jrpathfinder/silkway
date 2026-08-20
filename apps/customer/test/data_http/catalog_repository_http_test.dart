import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/network/api_client.dart';
import 'package:silkway_app/features/catalog/data/catalog_repository_http.dart';

import '../helpers/fakes.dart';

void main() {
  test('getForLocation GETs the location catalog endpoint and unwraps `data`', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/locations/ca-moscow-1/catalog');
      return (
        200,
        '{"data": {"locationId": "ca-moscow-1", "currency": "RUB", "categories": [], "items": []}}',
      );
    });

    final repo = CatalogRepositoryHttp(client);
    final response = await repo.getForLocation('ca-moscow-1');

    expect(response.locationId, 'ca-moscow-1');
    expect(response.items, isEmpty);
  });
}
