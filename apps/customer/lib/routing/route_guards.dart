import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/session_notifier.dart';

const _guardedPrefixes = ['/checkout', '/orders'];

/// Browse-without-auth, gate-at-checkout: only routes under [_guardedPrefixes]
/// redirect to the phone-entry screen when unauthenticated. Catalog, cart,
/// and promotions stay reachable unauthenticated (matches the design
/// reference: "phone login gated at checkout only").
String? checkoutRedirectGuard(Ref ref, GoRouterState state) {
  final path = state.uri.path;
  final needsAuth = _guardedPrefixes.any((prefix) => path.startsWith(prefix));
  if (!needsAuth) return null;

  final session = ref.read(sessionNotifierProvider);
  final isAuthenticated = session.valueOrNull?.isAuthenticated ?? false;
  if (isAuthenticated) return null;

  return '/auth/phone?returnTo=${Uri.encodeComponent(state.uri.toString())}';
}
