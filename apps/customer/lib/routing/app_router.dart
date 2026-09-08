import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/flavor.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/models/delivery.dart';
import '../core/providers.dart';
import '../features/auth/presentation/otp_verify_screen.dart';
import '../features/auth/presentation/phone_entry_screen.dart';
import '../features/cart/presentation/cart_badge.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/catalog/presentation/home_screen.dart';
import '../features/catalog/presentation/search_screen.dart';
import '../features/courier/presentation/courier_home_screen.dart';
import '../features/delivery/presentation/address_picker_screen.dart';
import '../features/loyalty/presentation/promotions_screen.dart';
import '../features/orders/presentation/checkout_screen.dart';
import '../features/orders/presentation/order_history_screen.dart';
import '../features/orders/presentation/order_status_screen.dart';
import '../features/payments/presentation/payment_webview_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/application/splash_gate.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'route_guards.dart';

/// Маршруты приложения. Таблица зависит от флейвора: у курьера свой,
/// короткий набор экранов.
final appRouterProvider = Provider<GoRouter>((ref) {
  final flavor = ref.watch(envProvider).flavor;
  return flavor == AppFlavor.courier ? _buildCourierRouter(ref) : _buildCustomerRouter(ref);
});

GoRouter _buildCustomerRouter(Ref ref) {
  // На повторных холодных запусках заставку пропускаем и открываем меню
  // сразу — см. SplashGate.
  final showSplash = ref.watch(showSplashProvider);
  return GoRouter(
    initialLocation: showSplash ? '/splash' : '/',
    redirect: (context, state) => checkoutRedirectGuard(ref, state),
    routes: [
      // Заставка — стартовый маршрут обоих флейворов. Внутри `go`, а не
      // `push`: экран не должен оставаться в стеке навигации, иначе кнопка
      // «Назад» на Android с главного экрана проигрывала бы ролик заново.
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(onFinished: () => context.go('/')),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _CustomerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
      // Поиск открывается поверх вкладок (push), а не как отдельная вкладка:
      // возврат должен приводить ровно туда, откуда пришли.
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/promotions',
        builder: (context, state) => const PromotionsScreen(),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => PhoneEntryScreen(returnTo: state.uri.queryParameters['returnTo']),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => OtpVerifyScreen(
          phone: state.uri.queryParameters['phone']!,
          returnTo: state.uri.queryParameters['returnTo'],
          devCode: state.uri.queryParameters['devCode'],
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/checkout/address',
        builder: (context, state) => AddressPickerScreen(initial: state.extra as DeliveryAddress?),
      ),
      GoRoute(
        path: '/checkout/payment',
        builder: (context, state) => PaymentWebviewScreen(orderId: state.uri.queryParameters['orderId']!),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) => OrderStatusScreen(orderId: state.pathParameters['orderId']!),
      ),
    ],
  );
}

GoRouter _buildCourierRouter(Ref ref) {
  final showSplash = ref.watch(showSplashProvider);
  return GoRouter(
    initialLocation: showSplash ? '/splash' : '/courier',
    routes: [
      // Та же заставка для курьерского флейвора, но выход — на /courier.
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(onFinished: () => context.go('/courier')),
      ),
      GoRoute(path: '/courier', builder: (context, state) => const CourierHomeScreen()),
    ],
  );
}

class _CustomerShell extends StatelessWidget {
  const _CustomerShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      // Контент уходит под бар, а не обрывается на его границе — иначе
      // размытие ниже показывало бы сплошной фон вместо страницы под ним.
      extendBody: true,
      body: _ShellSwitchTransition(index: shell.currentIndex, child: shell),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: NavigationBar(
            backgroundColor: scheme.surface.withValues(alpha: 0.7),
            selectedIndex: shell.currentIndex,
            onDestinationSelected: shell.goBranch,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: l10n.navMenu),
              NavigationDestination(
                icon: const CartBadge(child: Icon(Icons.shopping_basket_outlined)),
                label: l10n.navCart,
              ),
              NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.navProfile),
            ],
          ),
        ),
      ),
    );
  }
}

/// Лёгкое скольжение+проявление при смене вкладки — чисто декоративное,
/// поверх `shell`, а не вместо него: `shell` передаётся в [AnimatedBuilder]
/// как `child` и остаётся тем же виджетом на протяжении всей анимации, так
/// что go_router не теряет состояние веток (глубину навигации внутри
/// Корзины, скролл в Меню) при переключении. Перестроение shell с новым
/// ключом (как в AnimatedSwitcher) этого не гарантирует — поэтому не он.
class _ShellSwitchTransition extends StatefulWidget {
  const _ShellSwitchTransition({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_ShellSwitchTransition> createState() => _ShellSwitchTransitionState();
}

class _ShellSwitchTransitionState extends State<_ShellSwitchTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;
  // Слева направо или наоборот — так же, как при листании страниц, а не
  // однообразный наезд в одну сторону. Вычисляется один раз на переключение
  // в didUpdateWidget, а не на каждой сборке.
  bool _fromRight = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..value = 1;
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant _ShellSwitchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _fromRight = widget.index >= oldWidget.index;
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      child: widget.child,
      builder: (context, child) {
        final value = _curved.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * (_fromRight ? 18 : -18), 0),
            child: child,
          ),
        );
      },
    );
  }
}
