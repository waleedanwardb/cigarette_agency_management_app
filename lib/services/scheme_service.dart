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