import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cigarette_agency_management_app/models/brand.dart';

class BrandService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _brandCollection = FirebaseFirestore.instance.collection('brands');

  Stream<List<Brand>> getBrands() {
    return _brandCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Brand.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null)).toList();
    });
  }

  Future<void> addBrand(Brand brand) async {
    await _brandCollection.doc(brand.id).set(brand.toFirestore());
  }

  Future<void> updateBrand(Brand brand) async {
    await _brandCollection.doc(brand.id).update(brand.toFirestore());
  }

  Future<void> deleteBrand(String brandId) async {
    await _brandCollection.doc(brandId).delete();
  }
}