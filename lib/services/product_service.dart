// lib/services/product_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cigarette_agency_management_app/models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Stream<List<Product>> getProductsByBrandId(String brandId) {
    return _db
        .collection('products')
        .where('brandId', isEqualTo: brandId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // NEW: Method to get only non-lighter products
  Stream<List<Product>> getFactoryProducts() {
    return _db
        .collection('products')
        .where('brand', isNotEqualTo: 'Lighter Brand Name') // Use your actual lighter brand name here
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // NEW: Method to get only lighter products
  Stream<List<Product>> getLighterProducts() {
    return _db
        .collection('products')
        .where('brand', isEqualTo: 'Lighter Brand Name') // Use your actual lighter brand name here
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<void> addProduct(Product product, File? imageFile) async {
    String imageUrl = '';
    if (imageFile != null) {
      final ref = _storage.ref().child('product_images').child('${DateTime.now().toIso8601String()}');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }
    await _db.collection('products').add(product.copyWith(imageUrl: imageUrl).toFirestore());
  }

  Future<void> updateProduct(Product product, {File? newImage}) async {
    String imageUrl = product.imageUrl;
    if (newImage != null) {
      final ref = _storage.ref().child('product_images').child('${DateTime.now().toIso8601String()}');
      await ref.putFile(newImage);
      imageUrl = await ref.getDownloadURL();
    }
    await _db.collection('products').doc(product.id).update(product.copyWith(imageUrl: imageUrl).toFirestore());
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }
}