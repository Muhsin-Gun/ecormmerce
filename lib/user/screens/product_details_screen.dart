import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/support_utils.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/review_provider.dart';
import '../../shared/widgets/review_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/providers/wishlist_provider.dart';
import '../../shared/widgets/auth_button.dart';
import '../../shared/widgets/optimized_network_image.dart';
import '../../shared/widgets/product_card.dart';
import '../../main.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadReviews(widget.product.productId);
      context.read<ProductProvider>().loadRelatedProducts(
        widget.product.category,
        widget.product.productId,
      );
      if (mounted) {
        context.read<ProductProvider>().addToRecentlyViewed(widget.product.productId);
      }
    });
  }

  void _addToCart() {
    context.read<CartProvider>().addItem(widget.product, quantity: _quantity);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            // Use navigatorKey to avoid using stale context if widget is disposed
            ProMarketApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final imageUrls = (widget.product.images.isEmpty
            ? [widget.product.mainImage]
            : widget.product.images)
        .where((url) => url.isNotEmpty)
        .toList();
    final reviewProvider = context.watch<ReviewProvider>();
    final isDesktopWeb = kIsWeb && size.width >= 900;
    final imageHeaderHeight = isDesktopWeb ? 420.0 : size.height * 0.45;
    final ratingCount = reviewProvider.reviewCountFor(widget.product.productId);
    final rating = reviewProvider.averageRatingFor(widget.product.productId);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: imageHeaderHeight,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<WishlistProvider>(
                builder: (context, wishlist, _) {
                  final isInWishlist = wishlist.isInWishlist(widget.product.productId);
                  return IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Colors.red : Colors.white,
                      ),
                    ),
                    onPressed: () => wishlist.toggleWishlist(widget.product),
                  );
                }
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: imageUrls.length > 1,
                      onPageChanged: (index, reason) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    items: imageUrls.isEmpty
                        ? [
                            Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ),
                          ]
                        : imageUrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imageUrl = entry.value;
                      return Hero(
                        tag: 'product_image_${widget.product.productId}_$index',
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktopWeb ? 760 : double.infinity,
                            ),
                            child: OptimizedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              memCacheWidth: (1200 * MediaQuery.of(context).devicePixelRatio).round(),
                              placeholder: const Center(
                                child: SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // Indicator
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: imageUrls.asMap().entries.map((entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                _currentImageIndex == entry.key ? 1.0 : 0.4
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Product Info
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkNavy : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.product.brand?.toUpperCase() ?? '',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                ratingCount == 0 ? 'New' : rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                              Text(
                                ratingCount == 0 ? ' (0)' : ' ($ratingCount)',
                                style: TextStyle(
                                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingS),

                    // Name
                    Text(
                      widget.product.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Price
                    Row(
                      children: [
                        Text(
                          Formatters.formatCurrency(widget.product.price),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryIndigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.product.isOnSale &&
                            widget.product.compareAtPrice != null &&
                            widget.product.discountPercentage != null) ...[
                          const SizedBox(width: AppTheme.spacingM),
                          Text(
                            Formatters.formatCurrency(widget.product.compareAtPrice!),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.gray500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.product.discountPercentage!.toInt()}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Description
                    const SectionHeader(title: 'Description'),
                    Text(
                      widget.product.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? AppColors.gray300 : AppColors.gray700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Chat/Seller Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return OutlinedButton.icon(
                          onPressed: () => SupportUtils.startSupportChat(context),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat with Support'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: AppColors.electricPurple),
                            foregroundColor: AppColors.electricPurple,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Reviews Section
                    const SectionHeader(title: 'Reviews & Comments'),
                    Consumer<ReviewProvider>(
                      builder: (context, reviewProvider, child) {
                        if (reviewProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (reviewProvider.reviews.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              child: Column(
                                children: [
                                  Text(
                                    'No reviews yet. Be the first to comment.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () => _showAddReviewDialog(context),
                                    icon: const Icon(Icons.rate_review_outlined),
                                    label: const Text('Write a Review'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Show top 3 reviews
                        return Column(
                          children: [
                            ...reviewProvider.reviews.take(3).map((review) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                                child: ReviewCard(review: review),
                              );
                            }),
                            TextButton.icon(
                              onPressed: () => _showAddReviewDialog(context),
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text('Write a Review'),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: AppTheme.spacingL),

                    // Related Products
                    Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        if (provider.relatedProducts.isEmpty) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'You might also like'),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                                itemCount: provider.relatedProducts.length,
                                itemBuilder: (context, index) {
                                  final product = provider.relatedProducts[index];
                                  return Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: AppTheme.spacingM),
                                    child: ProductCard(
                                      product: product,
                                      heroTagSuffix: '_related_$index',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailsScreen(product: product),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 100), // Bottom padding for sticky bar
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // TODO: Check max stock
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              
              // Add to Cart Button
              Expanded(
                child: AuthButton(
                  text: 'Add to Cart',
                  onPressed: _addToCart,
                  isLoading: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddReviewDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to review')));
      return;
    }

    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                  ),
                  onPressed: () => setState(() => rating = index + 1.0),
                )),
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isEmpty) return;
                
                try {
                  await context.read<ReviewProvider>().addReview(
                    widget.product.productId,
                    auth.userModel!.userId,
                    auth.userModel!.name,
                    rating,
                    commentController.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  debugPrint('Review Error: $e');
                }
              }, 
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
