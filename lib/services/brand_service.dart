// lib/services/brand_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:cigarette_agency_management_app/models/brand.dart';

class BrandService {
  final CollectionReference _brandsCollection =
  FirebaseFirestore.instance.collection('brands');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream to get all brands
  Stream<List<Brand>> getBrands() {
    return _brandsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Brand.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // Add a new brand
  Future<void> addBrand(Brand brand, {File? brandLogo}) async {
    String? imageUrl;
    if (brandLogo != null) {
      imageUrl = await _uploadImage(brandLogo, 'brand_logos/${brand.name}_${DateTime.now().millisecondsSinceEpoch}.png');
    }
    final newBrandRef = await _brandsCollection.add(brand.toMap());
    if (imageUrl != null) {
      await newBrandRef.update({'imageUrl': imageUrl});
    }
  }

  // Update an existing brand
  Future<void> updateBrand(Brand brand, {File? newLogo}) async {
    String? imageUrl = brand.imageUrl;
    if (newLogo != null) {
      imageUrl = await _uploadImage(newLogo, 'brand_logos/${brand.name}_${DateTime.now().millisecondsSinceEpoch}.png');
    }
    await _brandsCollection.doc(brand.id).update(brand.copyWith(imageUrl: imageUrl).toMap());
  }

  // Delete a brand
  Future<void> deleteBrand(String brandId) async {
    await _brandsCollection.doc(brandId).delete();
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