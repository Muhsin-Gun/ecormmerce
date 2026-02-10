import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/product_provider.dart';
import 'add_edit_product_screen.dart';

class AdminProductsTab extends StatelessWidget {
  const AdminProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen()));
        },
        backgroundColor: AppColors.primaryIndigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return const Center(child: Text('No products yet. Add one!'));
          }

          return ListView.separated(
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
                      product.mainImage ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${product.brand} • Stock: ${product.stockQuantity}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.formatCurrency(product.price),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryIndigo),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete product'),
                              content: Text('Are you sure you want to delete "${product.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final deleted = await context.read<ProductProvider>().deleteProduct(product.productId);
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(deleted ? 'Product deleted' : 'Could not delete product'),
                              backgroundColor: deleted ? AppColors.success : AppColors.error,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
