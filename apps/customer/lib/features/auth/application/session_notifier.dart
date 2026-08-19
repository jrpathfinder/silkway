import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth.dart';
import '../../../core/ports/auth_repository.dart';
import '../../../core/providers.dart';
import '../data/auth_repository_http.dart';
import '../data/auth_repository_mock.dart';

class SessionState {
  const SessionState({this.accessToken, this.phone});

  final String? accessToken;
  final String? phone;

  bool get isAuthenticated => accessToken != null;

  /// Contract gap: `verifyOtp` returns no customer id (auth.controller.ts /
  /// auth.service.ts) — derive it from the phone number for now, matching
  /// `customer.phone_e164` as the natural key in schema.sql. Replace once the
  /// backend returns a real id (tracked in ADR-003).
  String? get customerId => phone;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = ref.watch(envProvider);
  return env.useMocks ? AuthRepositoryMock() : AuthRepositoryHttp(ref.watch(apiClientProvider));
});

class SessionNotifier extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final storage = ref.watch(secureStorageProvider);
    final hasSession = await storage.hasSession();
    if (!hasSession) return const SessionState();
    final token = await storage.readAccessToken();
    final phone = await storage.readPhone();
    return SessionState(accessToken: token, phone: phone);
  }

  Future<OtpRequestResult> requestOtp(String phone) {
    return ref.read(authRepositoryProvider).requestOtp(phone);
  }

  /// Returns true once verified and the session is persisted.
  Future<bool> verifyOtp(String phone, String code) async {
    final result = await ref.read(authRepositoryProvider).verifyOtp(phone, code);
    if (!result.verified || result.accessToken == null || result.refreshToken == null) {
      return false;
    }
    await ref.read(secureStorageProvider).saveSession(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken!,
          phone: result.phone ?? phone,
        );
    state = AsyncData(SessionState(accessToken: result.accessToken, phone: result.phone ?? phone));
    return true;
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearSession();
    state = const AsyncData(SessionState());
  }
}

final sessionNotifierProvider = AsyncNotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);
