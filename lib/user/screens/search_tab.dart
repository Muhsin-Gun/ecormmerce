import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/models/product_model.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/product_card.dart';
import 'product_details_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      context.read<ProductProvider>().searchProducts(value);
    });
  }

  void _showFilterSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSortModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar & Filter Button
                  _buildSearchBar(context, isDark),
                  const SizedBox(height: AppTheme.spacingM),

                  // Quick Category Filters
                  SizedBox(
                    height: 40,
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            CategoryChip(
                              label: 'All',
                              isSelected: provider.selectedCategory == null,
                              onTap: () => provider.setCategory(null),
                            ),
                            const SizedBox(width: 8),
                            ...AppConstants.productCategories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CategoryChip(
                                  label: category,
                                  isSelected:
                                      provider.selectedCategory == category,
                                  onTap: () => provider.setCategory(category),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: Selector<ProductProvider, bool>(
                selector: (_, p) => p.isLoading,
                builder: (context, isLoading, child) {
                  if (isLoading)
                    return const Center(child: CircularProgressIndicator());
                  return child!;
                },
                child: Selector<ProductProvider, List<ProductModel>>(
                  selector: (_, p) => p.products,
                  builder: (context, products, _) {
                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: isDark
                                  ? AppColors.gray600
                                  : AppColors.gray400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isDark
                                    ? AppColors.gray500
                                    : AppColors.gray500,
                              ),
                            ),
                            Selector<ProductProvider, bool>(
                              selector: (_, p) =>
                                  p.selectedCategory != null ||
                                  p.minPrice != null,
                              builder: (context, hasFilters, _) {
                                if (!hasFilters) return const SizedBox();
                                return TextButton(
                                  onPressed: () => context
                                      .read<ProductProvider>()
                                      .clearFilters(),
                                  child: const Text('Clear Filters'),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isWebLike = screenWidth >= 900;
                        final crossAxisCount =
                            constraints.maxWidth > 600 ? 3 : 2;
                        final gridAspectRatio = isWebLike
                            ? 0.86
                            : (screenWidth >= 600 ? 0.82 : 0.74);

                        return GridView.builder(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          cacheExtent: 800,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: gridAspectRatio,
                            crossAxisSpacing: AppTheme.spacingM,
                            mainAxisSpacing: AppTheme.spacingM,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ProductCard(
                              product: product,
                              heroTagSuffix: '_search_$index',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, _) {
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ProductProvider>().searchProducts('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[100],
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showFilterSortModal(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterSortModal extends StatefulWidget {
  @override
  State<_FilterSortModal> createState() => _FilterSortModalState();
}

class _FilterSortModalState extends State<_FilterSortModal> {
  late String _sortBy;
  late double? _minRating;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _sortBy = provider.currentSortBy;
    _minRating = provider.minRating;
    if (provider.minPrice != null)
      _minPriceController.text = provider.minPrice!.toStringAsFixed(0);
    if (provider.maxPrice != null)
      _maxPriceController.text = provider.maxPrice!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final provider = context.read<ProductProvider>();

    // Sort
    provider.sortProducts(_sortBy);

    // Rating
    provider.setMinRating(_minRating);

    // Price
    double? min = double.tryParse(_minPriceController.text);
    double? max = double.tryParse(_maxPriceController.text);
    provider.setPriceRange(min, max);

    Navigator.pop(context);
  }

  void _resetFilters() {
    final provider = context.read<ProductProvider>();
    provider.clearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        top: AppTheme.spacingL,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Sort Options
          Text('Sort By', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: 8,
            children: [
              _buildSortChip('Newest', 'newest'),
              _buildSortChip('Price: Low to High', 'price_asc'),
              _buildSortChip('Price: High to Low', 'price_desc'),
              _buildSortChip('Rating', 'rating'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Price Range
          Text('Price Range', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Rating
          Text('Minimum Rating', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [4.0, 3.0, 2.0, 1.0].map((rating) {
              final isSelected = _minRating == rating;
              return InkWell(
                onTap: () =>
                    setState(() => _minRating = isSelected ? null : rating),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.electricPurple.withOpacity(0.1)
                        : null,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.electricPurple
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(rating.toStringAsFixed(0),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.electricPurple
                                  : null)),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text('+',
                          style: TextStyle(
                              color: isSelected
                                  ? AppColors.electricPurple
                                  : null)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Apply Button
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _sortBy = value);
      },
      selectedColor: AppColors.electricPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}
