import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cigarette_agency_management_app/models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _productCollection = FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> getProducts() {
    return _productCollection
        .orderBy('brand')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null)).toList();
    });
  }

  Future<void> addProduct(Product product, {File? imageFile}) async {
    String? imageUrl = product.imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, 'product_images/${product.id}/product_pic.jpg');
    }

    final productToSave = product.copyWith(imageUrl: imageUrl);
    await _productCollection.doc(productToSave.id).set(productToSave.toFirestore());
  }

  Future<void> updateProduct(Product product, {File? imageFile}) async {
    String? imageUrl = product.imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, 'product_images/${product.id}/product_pic.jpg');
    }

    final updatedProduct = product.copyWith(imageUrl: imageUrl);
    await _productCollection.doc(updatedProduct.id).update(updatedProduct.toFirestore());
  }

  Future<void> deleteProduct(String productId) async {
    await _productCollection.doc(productId).delete();
  }

  Future<String?> _uploadImage(File imageFile, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}