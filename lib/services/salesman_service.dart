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

  Future<void> addSalesman(Salesman salesman, {File? profilePic, File? idCardFrontPic, File? idCardBackPic}) async {
    final newSalesmanRef = _salesmanCollection.doc();
    String? profileImageUrl;
    String? idCardFrontUrl;
    String? idCardBackUrl;

    if (profilePic != null) {
      profileImageUrl = await _uploadImage(profilePic, 'salesman_profiles/${newSalesmanRef.id}/profile_pic.jpg');
    }
    if (idCardFrontPic != null) {
      idCardFrontUrl = await _uploadImage(idCardFrontPic, 'salesman_profiles/${newSalesmanRef.id}/id_card_front.jpg');
    }
    if (idCardBackPic != null) {
      idCardBackUrl = await _uploadImage(idCardBackPic, 'salesman_profiles/${newSalesmanRef.id}/id_card_back.jpg');
    }

    final salesmanToSave = salesman.copyWith(
      id: newSalesmanRef.id,
      imageUrl: profileImageUrl ?? '',
      // Note: The Salesman model does not have image fields for ID cards. You will need to add them.
    );

    await newSalesmanRef.set(salesmanToSave.toFirestore());
  }

  Future<void> updateSalesman(Salesman salesman, {File? profilePic, File? idCardFrontPic, File? idCardBackPic}) async {
    String? profileImageUrl = salesman.imageUrl;
    String? idCardFrontUrl;
    String? idCardBackUrl;

    if (profilePic != null) {
      profileImageUrl = await _uploadImage(profilePic, 'salesman_profiles/${salesman.id}/profile_pic.jpg');
    }
    if (idCardFrontPic != null) {
      idCardFrontUrl = await _uploadImage(idCardFrontPic, 'salesman_profiles/${salesman.id}/id_card_front.jpg');
    }
    if (idCardBackPic != null) {
      idCardBackUrl = await _uploadImage(idCardBackPic, 'salesman_profiles/${salesman.id}/id_card_back.jpg');
    }

    await _salesmanCollection.doc(salesman.id).update(salesman.copyWith(imageUrl: profileImageUrl).toFirestore());
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

  Future<void> updateSalesmanTransaction(
      String salesmanId, SalesmanAccountTransaction transaction) async {
    final transactionCollection = _salesmanCollection.doc(salesmanId).collection('transactions');
    await transactionCollection.doc(transaction.id).update(transaction.toFirestore());
  }

  Stream<List<SalesmanAccountTransaction>> getSalesmanTransactionsInDateRange(
      String salesmanId, DateTime startDate, DateTime endDate) {
    return _salesmanCollection
        .doc(salesmanId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SalesmanAccountTransaction.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  Map<String, double> calculateSalesmanStock(List<SalesmanAccountTransaction> transactions) {
    final Map<String, double> stock = {};
    for (var t in transactions) {
      if (t.productName != null) {
        if (!stock.containsKey(t.productName)) {
          stock[t.productName!] = 0.0;
        }
        if (t.type == 'Stock Out') {
          stock[t.productName!] = stock[t.productName]! + (t.stockOutQuantity ?? 0.0);
        } else if (t.type == 'Stock Return') {
          stock[t.productName!] = stock[t.productName]! - (t.stockReturnQuantity ?? 0.0);
        }
      }
    }
    return stock;
  }

  double calculateSalesmanAccountTotal(List<SalesmanAccountTransaction> transactions) {
    double total = 0.0;
    for (var t in transactions) {
      if (t.type == 'Stock Out') {
        total += t.calculatedPrice ?? 0.0;
      } else if (t.type == 'Stock Return') {
        total += t.calculatedPrice ?? 0.0;
      } else if (t.type == 'Cash Received') {
        total -= t.cashReceived ?? 0.0;
      }
    }
    return total;
  }

  Future<void> deleteSalesmanTransaction(String salesmanId, String transactionId) async {
    await _salesmanCollection.doc(salesmanId).collection('transactions').doc(transactionId).delete();
  }

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
