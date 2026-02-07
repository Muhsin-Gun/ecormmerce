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
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'product_details_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _currentCarouselIndex = 0;
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProMarket'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConversationListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.products.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              children: [
                const SkeletonLoader(width: double.infinity, height: 180, borderRadius: AppTheme.radiusLarge),
                const SizedBox(height: 24),
                const SkeletonLoader(width: 150, height: 24),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SkeletonLoader.productCard(),
                    SkeletonLoader.productCard(),
                  ],
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async => await provider.refresh(),
            child: CustomScrollView(
              slivers: [
                // 1. Featured Carousel
                if (provider.featuredProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: AppTheme.spacingM),
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 180,
                            viewportFraction: 0.9,
                            enlargeCenterPage: true,
                            autoPlay: true,
                            onPageChanged: (index, reason) {
                              setState(() => _currentCarouselIndex = index);
                            },
                          ),
                          items: provider.featuredProducts.map((product) {
                            return Builder(
                              builder: (BuildContext context) {
                                return _buildFeaturedCard(context, product);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: provider.featuredProducts.asMap().entries.map((entry) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentCarouselIndex == entry.key
                                    ? AppColors.electricPurple
                                    : AppColors.gray300,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                // 1.5 Recently Viewed
                if (provider.recentlyViewedProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Recently Viewed'),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                            itemCount: provider.recentlyViewedProducts.length,
                            itemBuilder: (context, index) {
                              final product = provider.recentlyViewedProducts[index];
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
                  ),

                // 2. Categories
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SectionHeader(title: 'Categories'),
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
                                provider.clearFilters();
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
                                    provider.setCategory(category);
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

                // 3. New Arrivals (Vertical Grid)
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'New Arrivals',
                    actionText: 'See All',
                    onActionTap: () {
                      // Navigate to full list
                    },
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Responsive: Use LayoutBuilder for web
                      childAspectRatio: 0.7,
                      crossAxisSpacing: AppTheme.spacingM,
                      mainAxisSpacing: AppTheme.spacingM,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = provider.products[index];
                        return ProductCard(
                          product: product,
                          heroTagSuffix: '_grid_$index',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(product: product),
                              ),
                            );
                          },
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
                      childCount: provider.products.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, ProductModel product) {
    final hasImage = product.mainImage.isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        color: hasImage ? null : Colors.grey.shade300,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(product.mainImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
    );
  }
}
