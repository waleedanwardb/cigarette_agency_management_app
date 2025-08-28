// lib/services/scheme_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';

class SchemeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Scheme>> getSchemes() {
    return _db
        .collection('schemes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Scheme.fromFirestore(doc)).toList());
  }

  // NEW: Method to get applicable schemes for a product brand and quantity
  Future<List<Scheme>> getApplicableSchemes(String brandId, double quantity) async {
    // This is a simplified logic. In a real scenario, schemes might have conditions
    // based on quantity, price, or other factors. For this implementation,
    // we'll assume a scheme is applicable if it's for the given brand.
    final snapshot = await _db
        .collection('schemes')
        .where('isActive', isEqualTo: true)
        .where('productId', isEqualTo: brandId)
        .get();
    return snapshot.docs.map((doc) => Scheme.fromFirestore(doc)).toList();
  }

  // NEW: Method to calculate the total discount from a list of schemes
  double calculateTotalSchemeDiscount(List<Scheme> schemes, double quantity) {
    double totalDiscount = 0.0;
    for (var scheme in schemes) {
      // Assuming the scheme amount is per unit/pack
      totalDiscount += scheme.amount * quantity;
    }
    return totalDiscount;
  }

  Future<void> addScheme(Scheme scheme) {
    return _db.collection('schemes').add(scheme.toFirestore());
  }

  Future<void> updateScheme(Scheme scheme) {
    return _db.collection('schemes').doc(scheme.id).update(scheme.toFirestore());
  }

  Future<void> deleteScheme(String id) {
    return _db.collection('schemes').doc(id).delete();
  }
}