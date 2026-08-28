import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/providers.dart';
import '../../orders/presentation/providers/orders_providers.dart';
import 'providers/payment_providers.dart';

/// Hosted payment checkout, presented in-app (see docs/adr/003 for the
/// webview-vs-external-browser rationale). In mock mode there's no real
/// hosted page to load — PaymentRepositoryMock resolves the payment
/// synchronously — so this screen just shows a brief "processing" state
/// before moving on. In real mode it loads `confirmationUrl` in a WebView
/// and polls order status while the sheet is open (there's no push/webhook
/// channel to the client yet).
/// Оплата: размещённая платёжная страница во встроенном WebView.
class PaymentWebviewScreen extends ConsumerStatefulWidget {
  const PaymentWebviewScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends ConsumerState<PaymentWebviewScreen> {
  WebViewController? _webViewController;
  Timer? _pollTimer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final env = ref.read(envProvider);
      final checkout = await ref.read(paymentRepositoryProvider).createCheckout(widget.orderId);

      if (env.useMocks) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/orders/${widget.orderId}');
        return;
      }

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(checkout.confirmationUrl));
      _pollTimer = Timer.periodic(const Duration(seconds: 3), _poll);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _poll(Timer timer) async {
    try {
      final order = await ref.read(ordersRepositoryProvider).getById(widget.orderId);
      if (order.status.name != 'pendingPayment' && mounted) {
        timer.cancel();
        context.go('/orders/${widget.orderId}');
      }
    } catch (_) {
      // Одна неудавшаяся проверка не должна обрывать оплату — платёж мог
      // пройти, просто статус пока не удалось получить. Пробуем на
      // следующем тике; WebView с настоящей платёжной страницей остаётся
      // открытым и рабочим всё это время.
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оплата')),
      body: _error != null
          ? SwErrorState(title: 'Не удалось начать оплату', details: '$_error', onRetry: _start)
          : _webViewController == null
              ? const Center(child: CircularProgressIndicator())
              : WebViewWidget(controller: _webViewController!),
    );
  }
}
