import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/wishlist_provider.dart';
import 'optimized_network_image.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool isCompact;
  final String? heroTagSuffix;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.isCompact = false,
    this.heroTagSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Balanced decode size for faster scrolling on mobile/web grids.
    const imageCacheSize = 420;
    const borderRadius =
        BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium));

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: borderRadius,
                      child: Hero(
                        tag:
                            'product_${product.productId}${heroTagSuffix ?? ''}',
                        child: product.mainImage.isNotEmpty
                            ? OptimizedNetworkImage(
                                imageUrl: product.mainImage,
                                width: double.infinity,
                                height: double.infinity,
                                memCacheWidth: imageCacheSize,
                                placeholder: Container(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: Container(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  child:
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                      ),
                    ),

                    // Discount Badge
                    if (product.isOnSale && product.discountPercentage != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            '${product.discountPercentage!.toInt()}% OFF',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Wishlist Button - Using RepaintBoundary for micro-animations
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RepaintBoundary(
                        child: Selector<WishlistProvider, bool>(
                            selector: (_, wishlistProvider) => wishlistProvider
                                .isInWishlist(product.productId),
                            builder: (context, isInWishlist, _) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isInWishlist
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isInWishlist
                                        ? AppColors.error
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    context
                                        .read<WishlistProvider>()
                                        .toggleWishlist(product);
                                  },
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              );
                            }),
                      ),
                    ),
                  ],
                ),
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.brand ?? '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Formatters.formatCurrency(product.price),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryIndigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product.isOnSale &&
                                product.compareAtPrice != null)
                              Text(
                                Formatters.formatCurrency(
                                    product.compareAtPrice!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.gray500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        if (onAddToCart != null)
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.electricPurple,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: onAddToCart,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
