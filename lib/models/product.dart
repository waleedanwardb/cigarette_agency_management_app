// lib/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String brandId;
  final double price;
  final int stockQuantity;
  final bool isFrozen;
  final bool inStock;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandId,
    required this.price,
    required this.stockQuantity,
    required this.isFrozen,
    required this.inStock,
    this.imageUrl = '',
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      brandId: data['brandId'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stockQuantity: data['stockQuantity'] ?? 0,
      isFrozen: data['isFrozen'] ?? false,
      inStock: data['inStock'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'brandId': brandId,
      'price': price,
      'stockQuantity': stockQuantity,
      'isFrozen': isFrozen,
      'inStock': inStock,
      'imageUrl': imageUrl,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? brandId,
    double? price,
    int? stockQuantity,
    bool? isFrozen,
    bool? inStock,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      brandId: brandId ?? this.brandId,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isFrozen: isFrozen ?? this.isFrozen,
      inStock: inStock ?? this.inStock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}