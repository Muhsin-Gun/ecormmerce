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
      {
        'name': 'MacBook Pro 14"',
        'description': 'M3 Pro chip, 18GB memory, 512GB SSD. The ultimate pro laptop.',
        'price': 285000.0,
        'category': 'Electronics',
        'mainImage': 'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9',
        'isFeatured': true,
        'stock': 12,
        'brand': 'Apple',
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
        'name': 'Nike Air Jordan 1 Retro',
        'description': 'Iconic design that changed the game forever. High performance and style.',
        'price': 18500.0,
        'category': 'Fashion',
        'mainImage': 'https://images.unsplash.com/photo-1552346154-21d32810aba3',
        'isFeatured': false,
        'stock': 35,
        'brand': 'Nike',
      },
      {
        'name': 'Premium Leather Handbag',
        'description': 'Handcrafted Italian leather handbag with gold-tone hardware.',
        'price': 32000.0,
        'category': 'Fashion',
        'mainImage': 'https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d',
        'isFeatured': true,
        'stock': 20,
        'brand': 'Luxo',
      },
      // Home & Living
      {
        'name': 'Ergonomic Office Chair',
        'description': 'Maximum comfort for long work hours. Fully adjustable with lumbar support.',
        'price': 28000.0,
        'category': 'Home & Living',
        'mainImage': 'https://images.unsplash.com/photo-1505797149-43b0ad766a6b',
        'isFeatured': true,
        'stock': 15,
        'brand': 'ErgoWork',
      },
      {
        'name': 'Minimalist Ceramic Vase',
        'description': 'Hand-crafted ceramic vase for a clean and modern home aesthetic.',
        'price': 2500.0,
        'category': 'Home & Living',
        'mainImage': 'https://images.unsplash.com/photo-1581783898377-1c85bf937427',
        'isFeatured': false,
        'stock': 55,
        'brand': 'Handmade',
      },
      {
        'name': 'Modern Coffee Table',
        'description': 'Solid oak wood coffee table with a minimalist metal frame.',
        'price': 18000.0,
        'category': 'Home & Living',
        'mainImage': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88',
        'isFeatured': false,
        'stock': 10,
        'brand': 'NordicHaus',
      },
      // Beauty & Health
      {
        'name': 'Luxury French Perfume',
        'description': 'A sophisticated floral scent with notes of jasmine and sandalwood.',
        'price': 12500.0,
        'category': 'Beauty & Health',
        'mainImage': 'https://images.unsplash.com/photo-1541643600914-78b084683601',
        'isFeatured': true,
        'stock': 40,
        'brand': 'Éclat',
      },
      {
        'name': 'Advanced Skincare Serum',
        'description': 'Hyaluronic acid and Vitamin C for glowing, youthful skin.',
        'price': 4500.0,
        'category': 'Beauty & Health',
        'mainImage': 'https://images.unsplash.com/photo-1570172619380-4104bfccdb51',
        'isFeatured': false,
        'stock': 100,
        'brand': 'DermaPure',
      },
      // Sports & Outdoors
      {
        'name': 'Professional Football',
        'description': 'FIFA quality certified match ball for all weather conditions.',
        'price': 4800.0,
        'category': 'Sports & Outdoors',
        'mainImage': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018',
        'isFeatured': false,
        'stock': 200,
        'brand': 'AeroStrike',
      },
      {
        'name': 'Mountain Bike XT',
        'description': 'Aluminum frame, 21-speed gears, and disc brakes for rugged terrain.',
        'price': 55000.0,
        'category': 'Sports & Outdoors',
        'mainImage': 'https://images.unsplash.com/photo-1485965120184-e220f721d03e',
        'isFeatured': true,
        'stock': 8,
        'brand': 'TrailKing',
      },
      // Food & Beverages
      {
        'name': 'Premium Coffee Beans',
        'description': 'Single-origin Arabica beans roasted to perfection. Medium roast.',
        'price': 2200.0,
        'category': 'Food & Beverages',
        'mainImage': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e',
        'isFeatured': false,
        'stock': 150,
        'brand': 'RoastMaster',
      },
      // Automotive
      {
        'name': 'Car Dashboard Camera',
        'description': '4K resolution with night vision and wide-angle lens for safety.',
        'price': 9500.0,
        'category': 'Automotive',
        'mainImage': 'https://images.unsplash.com/photo-1506469717960-433cebe3f181',
        'isFeatured': false,
        'stock': 30,
        'brand': 'DriveSafe',
      },
      // Office Supplies
      {
        'name': 'Leather Bound Notebook',
        'description': 'Premium 120gsm paper with a classic leather cover for journaling.',
        'price': 1800.0,
        'category': 'Office Supplies',
        'mainImage': 'https://images.unsplash.com/photo-1531346878377-a5be20888e57',
        'isFeatured': false,
        'stock': 80,
        'brand': 'Scriptor',
      },
    ];

    for (var p in products) {
      final name = p['name'] as String;
      final category = p['category'] as String;
      final mainImage = p['mainImage'] as String;

      await collection.add({
        ...p,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'averageRating': 0.0,
        'reviewCount': 0,
        'images': [mainImage],
        'tags': [category, 'New'],
      });
    }
  }
}
