// lib/services/mt_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MTService {
  final CollectionReference _mtNamesCollection =
  FirebaseFirestore.instance.collection('mt_schemes');

  // Stream to get all MT scheme names
  Stream<List<String>> getMTNames() {
    return _mtNamesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Add a new MT scheme name
  Future<void> addMTName(String mtName) async {
    try {
      await _mtNamesCollection.doc(mtName).set({
        'name': mtName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding MT name: $e');
      rethrow;
    }
  }

  // Delete an MT scheme name
  Future<void> deleteMTName(String mtName) async {
    try {
      await _mtNamesCollection.doc(mtName).delete();
    } catch (e) {
      debugPrint('Error deleting MT name: $e');
      rethrow;
    }
  }
}