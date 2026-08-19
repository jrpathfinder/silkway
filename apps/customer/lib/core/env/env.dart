import '../../app/flavor.dart';

/// Compile-time app configuration, read once at startup from `--dart-define`
/// values. `useMocks` is the client-side mirror of the backend's
/// `DatabaseService.enabled` fallback pattern: when true, every repository
/// resolves to its mock implementation and the app needs no running backend.
class Env {
  const Env({
    required this.apiBaseUrl,
    required this.useMocks,
    required this.flavor,
  });

  final String apiBaseUrl;
  final bool useMocks;
  final AppFlavor flavor;

  factory Env.fromDartDefines(AppFlavor flavor) => Env(
        apiBaseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000',
        ),
        useMocks: const bool.fromEnvironment('USE_MOCKS', defaultValue: true),
        flavor: flavor,
      );
}
