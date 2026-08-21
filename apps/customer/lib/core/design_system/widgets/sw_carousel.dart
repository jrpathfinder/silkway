import 'package:flutter/material.dart';

/// Horizontal swipeable card carousel (featured dishes on Home, promotions,
/// etc.) — takes a card builder rather than a fixed card design so it stays
/// reusable across features.
class SwCarousel<T> extends StatelessWidget {
  const SwCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.height = 260,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.72,
          child: itemBuilder(context, items[index]),
        ),
      ),
    );
  }
}
