import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../../core/constants/constants.dart';

class DataSeeder {
  static Future<void> seedProducts() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection(AppConstants.productsCollection);

    final products = [
      // Electronics
      {
        'name': 'Samsung Galaxy S24 Ultra',
        'description': 'Experience the power of AI with the Galaxy S24 Ultra. Titanium frame and pro-grade camera.',
        'price': 145000.0,
        'category': 'Electronics',
        'mainImage': 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf',
        'isFeatured': true,
        'stock': 45,
        'brand': 'Samsung',
      },
      {
        'name': 'Sony WH-1000XM5',
        'description': 'Industry-leading noise cancellation and industry-leading sound quality.',
        'price': 42000.0,
        'category': 'Electronics',
        'mainImage': 'https://images.unsplash.com/photo-1546435770-a3e426bf472b',
        'isFeatured': true,
        'stock': 60,
        'brand': 'Sony',
      },
      // Fashion
      {
        'name': 'Ray-Ban Wayfarer Classic',
        'description': 'The most recognizable style in history. Since its design in 1952.',
        'price': 16500.0,
        'category': 'Fashion',
        'mainImage': 'https://images.unsplash.com/photo-1572635196237-14b3f281503f',
        'isFeatured': true,
        'stock': 120,
        'brand': 'Ray-Ban',
      },
      {
        'name': 'Nike Air Jordan 1 Reto',
        'description': 'Iconic design that changed the game forever. High performance and style.',
        'price': 18500.0,
        'category': 'Fashion',
        'mainImage': 'https://images.unsplash.com/photo-1552346154-21d32810aba3',
        'isFeatured': false,
        'stock': 35,
        'brand': 'Nike',
      },
      // Home Decor
      {
        'name': 'Ergonomic Office Chair',
        'description': 'Maximum comfort for long work hours. Fully adjustable with lumbar support.',
        'price': 28000.0,
        'category': 'Home Decor',
        'mainImage': 'https://images.unsplash.com/photo-1505797149-43b0ad766a6b',
        'isFeatured': true,
        'stock': 15,
        'brand': 'ErgoWork',
      },
      {
        'name': 'Minimalist Ceramic Vase',
        'description': 'Hand-crafted ceramic vase for a clean and modern home aesthetic.',
        'price': 2500.0,
        'category': 'Home Decor',
        'mainImage': 'https://images.unsplash.com/photo-1581783898377-1c85bf937427',
        'isFeatured': false,
        'stock': 55,
        'brand': 'Handmade',
      },
    ];

    for (var p in products) {
      await collection.add({
        ...p,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'averageRating': 4.5,
        'reviewCount': 12,
        'images': [p['mainImage']],
        'tags': [p['category'], 'New'],
      });
    }
  }
}
