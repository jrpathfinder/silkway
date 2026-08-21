import 'package:flutter/material.dart';

/// Renders a [CatalogItem.imageUrl] regardless of whether it's a bundled
/// asset path (today, from CatalogRepositoryMock) or a remote URL (once the
/// backend adds an image field) — one call site for both. Falls back to a
/// placeholder when there's no image at all.
class DishImage extends StatelessWidget {
  const DishImage({
    super.key,
    required this.imageUrl,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.backgroundColor,
  });

  final String? imageUrl;
  final BorderRadius? borderRadius;

  /// Карточкам в списке нужна обрезанная заливка «под край» — это значение
  /// по умолчанию ([BoxFit.cover]). Шапке карточки блюда нужно, наоборот,
  /// видеть тарелку целиком на белом фоне (референс «Империя Пиццы») — для
  /// этого передаём [BoxFit.contain] и белый [backgroundColor].
  final BoxFit fit;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final radius = borderRadius ?? BorderRadius.circular(12);

    if (url == null) {
      return _Placeholder(borderRadius: radius);
    }

    final image = url.startsWith('assets/')
        ? Image.asset(url, fit: fit)
        : Image.network(url, fit: fit);

    return ClipRRect(
      borderRadius: radius,
      child: backgroundColor == null
          ? image
          : Container(color: backgroundColor, child: image),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xffead8c5), borderRadius: borderRadius),
      child: const Center(child: Icon(Icons.restaurant, size: 40, color: Color(0xffb9633d))),
    );
  }
}
