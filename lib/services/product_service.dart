// lib/services/product_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:cigarette_agency_management_app/models/product.dart';

class ProductService {
  final CollectionReference _productsCollection =
  FirebaseFirestore.instance.collection('products');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get a stream of all products
  Stream<List<Product>> getProducts() {
    return _productsCollection.orderBy('brand').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // Get a stream of products for a specific brand
  Stream<List<Product>> getProductsByBrandId(String brandId) {
    return _productsCollection.where('brandId', isEqualTo: brandId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // Add a new product
  Future<void> addProduct(Product product, File? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, 'product_images/${product.name}_${DateTime.now().millisecondsSinceEpoch}.png');
    }
    final newProductRef = await _productsCollection.add(product.toMap());
    if (imageUrl != null) {
      await newProductRef.update({'imageUrl': imageUrl});
    }
  }

  // Update an existing product
  Future<void> updateProduct(Product product, {File? newImage}) async {
    String? imageUrl = product.imageUrl;
    if (newImage != null) {
      imageUrl = await _uploadImage(newImage, 'product_images/${product.name}_${DateTime.now().millisecondsSinceEpoch}.png');
    }
    await _productsCollection.doc(product.id).update(product.copyWith(imageUrl: imageUrl).toMap());
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }

  Future<String?> _uploadImage(File imageFile, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}