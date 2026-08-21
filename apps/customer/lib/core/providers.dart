import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env/env.dart';
import 'network/api_client.dart';
import 'storage/local_kv.dart';
import 'storage/secure_storage.dart';

/// Overridden in main_customer.dart/main_courier.dart with the flavor's
/// concrete [Env] — never read before that override is applied (see
/// app/app.dart's runSilkwayApp).
final envProvider = Provider<Env>((ref) {
  throw UnimplementedError('envProvider must be overridden in main_*.dart with Env.fromDartDefines(flavor)');
});

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final localKvProvider = Provider<LocalKv>((ref) => LocalKv());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(envProvider), ref.watch(secureStorageProvider));
});
