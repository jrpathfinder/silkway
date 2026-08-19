import 'package:dio/dio.dart';

import '../env/env.dart';
import '../storage/secure_storage.dart';

/// Thin wrapper around a configured [Dio] instance shared by every
/// `*RepositoryHttp` implementation. Attaches the stored access token (if
/// any) to every request.
class ApiClient {
  ApiClient(Env env, SecureStorage secureStorage)
      : dio = Dio(BaseOptions(
          baseUrl: env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await secureStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      // TODO: the backend issues no real expiring JWT yet (static dev tokens
      // in auth.service.ts) — add refresh-on-401 handling once it does.
      handler.next(options);
    }));
  }

  final Dio dio;
}
