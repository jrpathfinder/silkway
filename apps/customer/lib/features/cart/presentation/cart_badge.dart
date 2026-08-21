import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/cart_notifier.dart';

/// Счётчик товаров поверх иконки корзины в нижней навигации.
/// Прячется, когда корзина пуста.
///
/// При изменении числа бейдж коротко подпрыгивает: добавление происходит на
/// другом экране, и без этого движения легко не заметить, что товар вообще
/// попал в корзину.
class CartBadge extends ConsumerStatefulWidget {
  const CartBadge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends ConsumerState<CartBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = ref.watch(cartNotifierProvider.select((cart) => cart.itemCount));

    ref.listen(cartNotifierProvider.select((cart) => cart.itemCount), (previous, next) {
      // Прыгаем только когда товаров стало больше: на удалении подпрыгивающий
      // бейдж выглядел бы как поощрение не того действия.
      if (previous != null && next > previous && !MediaQuery.disableAnimationsOf(context)) {
        _controller.forward(from: 0);
      }
    });

    if (itemCount == 0) return widget.child;

    return ScaleTransition(
      scale: _scale,
      child: Badge(label: Text('$itemCount'), child: widget.child),
    );
  }
}
