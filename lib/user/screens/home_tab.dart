import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/product_model.dart';
import '../../shared/screens/conversation_list_screen.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/optimized_network_image.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'product_details_screen.dart';
import 'notification_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ValueNotifier<int> _currentCarouselIndex = ValueNotifier<int>(0);
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProMarket'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConversationListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await context.read<ProductProvider>().refresh(),
        child: CustomScrollView(
          cacheExtent: 200,
          slivers: [
            // 0. Loading State - Only rebuilds if loading changes
            Selector<ProductProvider, bool>(
              selector: (_, p) => p.isLoading && p.products.isEmpty,
              builder: (context, isLoading, _) {
                if (!isLoading) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SkeletonLoader(width: double.infinity, height: 180, borderRadius: AppTheme.radiusLarge),
                      const SizedBox(height: 24),
                      const SkeletonLoader(width: 150, height: 24),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          SkeletonLoader(width: 150, height: 200, borderRadius: AppTheme.radiusMedium),
                          SizedBox(width: 16),
                          SkeletonLoader(width: 150, height: 200, borderRadius: AppTheme.radiusMedium),
                        ],
                      ),
                    ]),
                  ),
                );
              },
            ),

            // 1. Featured Carousel
            Selector<ProductProvider, List<ProductModel>>(
              selector: (_, p) => p.featuredProducts,
              builder: (context, featuredProducts, _) {
                if (featuredProducts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: AppTheme.spacingM),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 180,
                          viewportFraction: 0.9,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          onPageChanged: (index, _) => _currentCarouselIndex.value = index,
                        ),
                        items: featuredProducts.map((product) => _buildFeaturedCard(context, product)).toList(),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      ValueListenableBuilder<int>(
                        valueListenable: _currentCarouselIndex,
                        builder: (context, index, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: featuredProducts.asMap().entries.map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == entry.key ? AppColors.electricPurple : AppColors.gray300,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // 1.5 Recently Viewed
            Selector<ProductProvider, List<ProductModel>>(
              selector: (_, p) => p.recentlyViewedProducts,
              builder: (context, recentlyViewed, _) {
                if (recentlyViewed.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Recently Viewed'),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                          itemCount: recentlyViewed.length,
                          itemBuilder: (context, index) {
                            final product = recentlyViewed[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: AppTheme.spacingM),
                              child: ProductCard(
                                product: product,
                                heroTagSuffix: '_recent_$index',
                                isCompact: true,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product))),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 2. Categories
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(title: 'Categories'),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                      children: [
                        CategoryChip(
                          label: 'All',
                          isSelected: _selectedCategory == 'All',
                          onTap: () {
                            setState(() => _selectedCategory = 'All');
                            context.read<ProductProvider>().clearFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        ...AppConstants.productCategories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CategoryChip(
                              label: category,
                              isSelected: _selectedCategory == category,
                              onTap: () {
                                setState(() => _selectedCategory = category);
                                context.read<ProductProvider>().setCategory(category);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. New Arrivals Header
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'New Arrivals',
                actionText: 'See All',
              ),
            ),

            // 4. Products Grid - Rebuilds ONLY when product list changes
            Selector<ProductProvider, List<ProductModel>>(
              selector: (_, p) => p.products,
              builder: (context, products, _) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: AppTheme.spacingM,
                      mainAxisSpacing: AppTheme.spacingM,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          heroTagSuffix: '_grid_$index',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product))),
                          onAddToCart: () {
                            context.read<CartProvider>().addItem(product);
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                      childCount: products.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                    ),
                  ),
                );
              },
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, ProductModel product) {
    final hasImage = product.mainImage.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            OptimizedNetworkImage(
              imageUrl: product.mainImage,
              fit: BoxFit.cover,
              memCacheWidth: (720 * MediaQuery.of(context).devicePixelRatio).round(),
              errorWidget: Container(
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            )
          else
            Container(
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.electricPurple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
