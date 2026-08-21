import 'app/app.dart';
import 'app/flavor.dart';

/// Точка входа покупательского приложения.
///
/// Второй бинарник — main_courier.dart; отличаются только флейвором, который
/// определяет и конфигурацию, и набор маршрутов.
void main() => runSilkwayApp(AppFlavor.customer);
