import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';

class SchemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a stream of all schemes from Firestore
  Stream<List<Scheme>> getSchemes() {
    return _firestore.collection('schemes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Scheme.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Add a new scheme to Firestore
  Future<void> addScheme(Scheme scheme) async {
    await _firestore.collection('schemes').add(scheme.toMap());
  }

  // Update an existing scheme in Firestore
  Future<void> updateScheme(Scheme scheme) async {
    await _firestore.collection('schemes').doc(scheme.id).update(scheme.toMap());
  }

  // Delete a scheme from Firestore
  Future<void> deleteScheme(String schemeId) async {
    await _firestore.collection('schemes').doc(schemeId).delete();
  }
}