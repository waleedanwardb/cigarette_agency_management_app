// lib/services/salesman_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/models/arrear.dart';

class SalesmanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _salesmanCollection = FirebaseFirestore.instance.collection('salesmen');
  final CollectionReference _arrearCollection = FirebaseFirestore.instance.collection('arrears');

  Stream<List<Salesman>> getSalesmen() {
    return _salesmanCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Salesman.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null)).toList();
    });
  }

  Future<void> addSalesman(Salesman salesman, {File? profilePic}) async {
    final newSalesmanRef = _salesmanCollection.doc();
    String? imageUrl;

    if (profilePic != null) {
      imageUrl = await _uploadImage(profilePic, 'salesman_profiles/${newSalesmanRef.id}/profile_pic.jpg');
    }

    final salesmanToSave = salesman.copyWith(
      id: newSalesmanRef.id,
      imageUrl: imageUrl ?? '',
    );

    await newSalesmanRef.set(salesmanToSave.toFirestore());
  }

  Future<void> updateSalesman(Salesman salesman, {File? profilePic}) async {
    String? imageUrl = salesman.imageUrl;

    if (profilePic != null) {
      imageUrl = await _uploadImage(profilePic, 'salesman_profiles/${salesman.id}/profile_pic.jpg');
    }

    await _salesmanCollection.doc(salesman.id).update(salesman.copyWith(imageUrl: imageUrl).toFirestore());
  }

  Future<void> deleteSalesman(String salesmanId) async {
    await _salesmanCollection.doc(salesmanId).delete();
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

  Stream<List<SalesmanAccountTransaction>> getSalesmanTransactions(String salesmanId) {
    return _salesmanCollection
        .doc(salesmanId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SalesmanAccountTransaction.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  Future<void> recordSalesmanTransaction({
    required String salesmanId,
    required SalesmanAccountTransaction transaction,
  }) async {
    final transactionCollection = _salesmanCollection.doc(salesmanId).collection('transactions');
    await transactionCollection.add(transaction.toFirestore());
  }

  // New methods for Arrear management
  Future<void> addArrear(Arrear arrear) async {
    await _arrearCollection.add(arrear.toFirestore());
  }

  Future<void> updateArrear(Arrear arrear) async {
    await _arrearCollection.doc(arrear.id).update(arrear.toFirestore());
  }

  Future<void> deleteArrear(String arrearId) async {
    await _arrearCollection.doc(arrearId).delete();
  }

  Stream<List<Arrear>> getArrears() {
    return _arrearCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Arrear.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}