// lib/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String brandId;
  final double price;
  final bool inStock;
  final int stockQuantity;
  final bool isFrozen;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandId,
    required this.price,
    required this.inStock,
    required this.stockQuantity,
    required this.isFrozen,
    required this.imageUrl,
  });

  // Factory constructor to create a Product object from a Firestore document
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      brandId: data['brandId'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      inStock: data['inStock'] ?? false,
      stockQuantity: data['stockQuantity'] ?? 0,
      isFrozen: data['isFrozen'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  // Method to convert a Product object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'brandId': brandId,
      'price': price,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'isFrozen': isFrozen,
      'imageUrl': imageUrl,
    };
  }

  // A helper method for updating a product with new values
  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? brandId,
    double? price,
    bool? inStock,
    int? stockQuantity,
    bool? isFrozen,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      brandId: brandId ?? this.brandId,
      price: price ?? this.price,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isFrozen: isFrozen ?? this.isFrozen,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}