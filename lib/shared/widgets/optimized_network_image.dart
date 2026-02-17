import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable network image tuned for smoother scrolling and lower decode cost.
class OptimizedNetworkImage extends StatelessWidget {
  static final Map<String, Future<String?>> _resolvedStorageUrlCache = {};

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final FilterQuality filterQuality;
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
    this.filterQuality = FilterQuality.low,
    this.errorWidget,
    this.placeholder,
  });

  String _optimizedImageUrl(String raw) {
    if (raw.isEmpty) return raw;

    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;

    if (uri.scheme.isEmpty) {
      if (raw.startsWith('//')) {
        return 'https:$raw';
      }
      return raw;
    }

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

    return raw;
  }

  static const int maxWidthDiskCacheDefault = 900;

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl.trim();
    if (raw.isEmpty) {
      return _buildError();
    }

    final httpsCandidate = _toHttpsIfDomainOnly(raw);
    final initialCandidate = httpsCandidate ?? raw;
    final optimizedUrl = _optimizedImageUrl(initialCandidate);

    if (!_isRemoteImageUrl(optimizedUrl)) {
      if (_canResolveStorageUrl(raw)) {
        final future = _resolvedStorageUrlCache.putIfAbsent(
          raw,
          () => _resolveStorageUrl(raw),
        );
        return FutureBuilder<String?>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return placeholder ?? _defaultShimmer();
            }
            final resolved = (snapshot.data ?? '').trim();
            if (_isRemoteImageUrl(resolved)) {
              return _buildCachedNetworkImage(_optimizedImageUrl(resolved));
            }
            return _buildError();
          },
        );
      }
      return _buildError();
    }

    return _buildCachedNetworkImage(optimizedUrl);
  }

  Widget _buildCachedNetworkImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxHeightDiskCache: 800,
      maxWidthDiskCache: maxWidthDiskCacheDefault,
      filterQuality: filterQuality,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => placeholder ?? _defaultShimmer(),
      errorWidget: (_, __, ___) => _buildError(),
    );
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, size: 32),
        );
  }

  String? _toHttpsIfDomainOnly(String url) {
    if (url.contains('://')) return null;
    final isLikelyDomain =
        RegExp(r'^[A-Za-z0-9.-]+\.[A-Za-z]{2,}(/.*)?$').hasMatch(url);
    if (!isLikelyDomain) return null;
    return 'https://$url';
  }

  bool _canResolveStorageUrl(String url) {
    if (url.startsWith('gs://')) return true;
    if (url.contains('://')) return false;
    if (url.startsWith('//')) return false;
    // Firebase Storage object path e.g. "products/image.jpg"
    return url.contains('/');
  }

  Future<String?> _resolveStorageUrl(String url) async {
    try {
      if (url.startsWith('gs://')) {
        return await FirebaseStorage.instance.refFromURL(url).getDownloadURL();
      }
      return await FirebaseStorage.instance.ref(url).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  bool _isRemoteImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
  }

  Widget _defaultShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.grey.shade300),
    );
  }
}
