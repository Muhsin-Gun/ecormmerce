import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/services/audit_log_service.dart';
import 'add_edit_product_screen.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProducts());
  }

  Future<void> _refreshProducts() async {
    final provider = context.read<ProductProvider>();
    provider.clearFilters();
    await provider.loadProducts(refresh: true);
  }

  Future<void> _openAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
    if (!mounted) return;
    await _refreshProducts();
  }

  Future<void> _openEditProduct(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    );
    if (!mounted) return;
    await _refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProduct,
        backgroundColor: AppColors.primaryIndigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'No products yet.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    const Text(
                      'Add your first product to start selling.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    OutlinedButton.icon(
                      onPressed: _openAddProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    TextButton.icon(
                      onPressed: _refreshProducts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: provider.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = provider.products[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.mainImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${product.brand} - Stock: ${product.stockQuantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.formatCurrency(product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _openEditProduct(product),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: AppColors.error,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete product'),
                                content: Text(
                                  'Are you sure you want to delete "${product.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;
                            if (!context.mounted) return;

                            final productProvider = context.read<ProductProvider>();
                            final deleted = await productProvider.deleteProduct(
                              product.productId,
                            );
                            if (!context.mounted) return;

                            if (deleted) {
                              await AuditLogService.log(
                                action: 'PRODUCT_DELETE',
                                target: product.productId,
                                metadata: {
                                  'name': product.name,
                                  'category': product.category,
                                },
                              );
                              if (!context.mounted) return;
                              AppFeedback.success(context, 'Product deleted');
                              await _refreshProducts();
                            } else {
                              AppFeedback.error(
                                context,
                                'Could not delete product.',
                                nextStep: 'Please retry.',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
