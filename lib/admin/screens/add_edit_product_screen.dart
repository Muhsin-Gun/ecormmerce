import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/widgets/auth_button.dart';
import '../../shared/widgets/auth_text_field.dart';
import '../../shared/services/cloudinary_service.dart';
import 'dart:io';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product; // If null, add mode

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;
  XFile? _pickedFile;

  String _selectedCategory = AppConstants.productCategories[0];
  bool _isOnSale = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name);
    _brandController = TextEditingController(text: p?.brand);
    _descController = TextEditingController(text: p?.description);
    _priceController = TextEditingController(text: p?.price.toString());
    _stockController = TextEditingController(text: p?.stockQuantity.toString() ?? '10');
    _imageController = TextEditingController(text: p?.mainImage);
    
    if (p != null) {
      _selectedCategory = p.category;
      _isOnSale = p.isOnSale;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _pickedFile = image);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ProductProvider>();
      final name = _nameController.text.trim();
      final brand = _brandController.text.trim();
      final desc = _descController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final stock = int.parse(_stockController.text.trim());
      
      // Handle Image Upload
      String? imageUrl = _imageController.text.trim();
      
      if (_pickedFile != null) {
        final uploadedUrl = await CloudinaryService.uploadImage(_pickedFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload image');
        }
      }

      if (widget.product == null) {
        // ADD
        final newProduct = ProductModel(
          productId: '', 
          name: name,
          description: desc,
          price: price,
          category: _selectedCategory,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          brand: brand,
          stock: stock,
          isActive: true,
          isOnSale: _isOnSale,
          createdAt: DateTime.now(),
          images: imageUrl.isNotEmpty ? [imageUrl] : [],
        );
        
        await provider.addProduct(newProduct);
      } else {
        // UPDATE
        final updatedProduct = widget.product!.copyWith(
          name: name,
          description: desc,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          category: _selectedCategory,
          brand: brand,
          stock: stock,
          isOnSale: _isOnSale,
          updatedAt: DateTime.now(),
        );
        
        await provider.updateProduct(updatedProduct);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null ? 'Product Added' : 'Product Updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthTextField(
                controller: _nameController,
                labelText: 'Product Name',
                prefixIcon: Icons.local_offer,
                validator: Validators.validateRequired,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _brandController,
                labelText: 'Brand',
                prefixIcon: Icons.branding_watermark,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _priceController,
                      labelText: 'Price (KES)',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AuthTextField(
                      controller: _stockController,
                      labelText: 'Stock Qty',
                      prefixIcon: Icons.inventory,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateRequired,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
               DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category, color: AppColors.gray500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AppConstants.productCategories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
               
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _pickedFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            _pickedFile!.path, // Note: On mobile this should be Image.file, on web Image.network
                            // For simplicity assuming mobile path works or handling cross-platform
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const Center(child: Icon(Icons.check_circle, size: 50, color: AppColors.success)),
                          ),
                        )
                      : (_imageController.text.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                _imageController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image)),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to add image', style: TextStyle(color: Colors.grey)),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 8),
              if (_pickedFile != null)
                const Center(
                  child: Text(
                    'Image selected (Will upload on save)', 
                    style: TextStyle(color: AppColors.electricPurple, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              
              AuthTextField(
                controller: _descController,
                labelText: 'Description',
                prefixIcon: Icons.description,
                maxLines: 4,
                validator: Validators.validateRequired,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('On Sale'),
                value: _isOnSale,
                activeColor: AppColors.electricPurple,
                onChanged: (val) => setState(() => _isOnSale = val),
              ),
              const SizedBox(height: 32),
              AuthButton(
                text: widget.product == null ? 'Create Product' : 'Update Product',
                onPressed: _saveProduct,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
