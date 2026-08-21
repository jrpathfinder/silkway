import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/location.dart';
import '../../../../core/ports/locations_repository.dart';
import '../../../../core/providers.dart';
import '../../data/locations_repository_http.dart';
import '../../data/locations_repository_mock.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  final env = ref.watch(envProvider);
  return env.useMocks ? LocationsRepositoryMock() : LocationsRepositoryHttp(ref.watch(apiClientProvider));
});

final activeLocationsProvider = FutureProvider<List<RestaurantLocation>>((ref) {
  return ref.watch(locationsRepositoryProvider).listActive();
});

/// The customer's currently selected "home restaurant" — defaults to the
/// first active location once loaded. Selecting from the location-picker
/// sheet updates this.
final selectedLocationIdProvider = StateProvider<String?>((ref) => null);
