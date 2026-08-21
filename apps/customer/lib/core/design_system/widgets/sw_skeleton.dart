import 'package:flutter/material.dart';

import '../tokens/sw_spacing.dart';

/// Прямоугольник-заглушка с мягким пульсом — основа скелетонов загрузки.
///
/// Скелетон честнее спиннера: он показывает, какой формы будет контент,
/// поэтому переход к данным не выглядит рывком. Спиннер же сообщает только
/// «что-то происходит».
///
/// Анимация уважает «Уменьшение движения» в настройках iOS: при включённой
/// опции пульс не запускается вовсе.
class SwSkeleton extends StatefulWidget {
  const SwSkeleton({super.key, this.width, this.height = 16, this.radius = SwSpacing.radiusSm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<SwSkeleton> createState() => _SwSkeletonState();
}

class _SwSkeletonState extends State<SwSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, Theme.of(context).colorScheme.outlineVariant, _controller.value * 0.6),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
