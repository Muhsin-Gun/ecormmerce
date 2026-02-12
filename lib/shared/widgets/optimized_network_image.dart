import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Reusable network image tuned for smoother scrolling and lower decode cost.
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? errorWidget;
  final Widget? placeholder;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.errorWidget,
    this.placeholder,
  });

  String _optimizedImageUrl() {
    if (imageUrl.isEmpty) return imageUrl;

    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return imageUrl;

    // Unsplash supports query-based transforms.
    if (uri.host.contains('images.unsplash.com')) {
      final targetWidth = memCacheWidth ?? maxWidthDiskCacheDefault;
      final qp = Map<String, String>.from(uri.queryParameters)
        ..putIfAbsent('auto', () => 'format')
        ..putIfAbsent('fit', () => 'crop')
        ..putIfAbsent('q', () => '75')
        ..putIfAbsent('w', () => '$targetWidth');
      return uri.replace(queryParameters: qp).toString();
    }

    return imageUrl;
  }

  static const int maxWidthDiskCacheDefault = 900;

  @override
  Widget build(BuildContext context) {
    final optimizedUrl = _optimizedImageUrl();

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxHeightDiskCache: 800,
      maxWidthDiskCache: maxWidthDiskCacheDefault,
      filterQuality: FilterQuality.none, // Fastest rendering
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) =>
          placeholder ?? Container(color: Colors.grey[300]),
      errorWidget: (_, __, ___) => errorWidget ?? const Icon(Icons.broken_image_outlined, size: 32),
    );
  }
}
