// lib/services/salesman_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:flutter/foundation.dart';

class SalesmanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _salesmanCollection = FirebaseFirestore.instance.collection('salesmen');

  Stream<List<Salesman>> getSalesmen() {
    return _salesmanCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Salesman.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null)).toList();
    });
  }

  // FIX: Added optional named parameters for image files
  Future<void> addSalesman(Salesman salesman, {File? profilePic, File? idFrontPic, File? idBackPic}) async {
    String? profileImageUrl = salesman.imageUrl;
    String? idFrontImageUrl;
    String? idBackImageUrl;

    // Upload images if provided
    if (profilePic != null) {
      profileImageUrl = await uploadImage(profilePic, 'salesman_profiles/${salesman.id}/profile_pic.jpg');
    }
    if (idFrontPic != null) {
      idFrontImageUrl = await uploadImage(idFrontPic, 'salesman_id_cards/${salesman.id}/id_front.jpg');
    }
    if (idBackPic != null) {
      idBackImageUrl = await uploadImage(idBackPic, 'salesman_id_cards/${salesman.id}/id_back.jpg');
    }

    final salesmanToSave = salesman.copyWith(
      imageUrl: profileImageUrl,
      // Assume Salesman model has these fields and update them
      // idCardFrontImageUrl: idFrontImageUrl,
      // idCardBackImageUrl: idBackImageUrl,
    );

    await _salesmanCollection.doc(salesmanToSave.id).set(salesmanToSave.toFirestore());
  }

  // FIX: Added optional named parameters for image files
  Future<void> updateSalesman(Salesman salesman, {File? profilePic, File? idFrontPic, File? idBackPic}) async {
    String? profileImageUrl = salesman.imageUrl;
    String? idFrontImageUrl;
    String? idBackImageUrl;

    if (profilePic != null) {
      profileImageUrl = await uploadImage(profilePic, 'salesman_profiles/${salesman.id}/profile_pic.jpg');
    }
    if (idFrontPic != null) {
      idFrontImageUrl = await uploadImage(idFrontPic, 'salesman_id_cards/${salesman.id}/id_front.jpg');
    }
    if (idBackPic != null) {
      idBackImageUrl = await uploadImage(idBackPic, 'salesman_id_cards/${salesman.id}/id_back.jpg');
    }

    Map<String, dynamic> updateData = salesman.toFirestore();
    if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
    // if (idFrontImageUrl != null) updateData['idCardFrontImageUrl'] = idFrontImageUrl;
    // if (idBackImageUrl != null) updateData['idCardBackImageUrl'] = idBackImageUrl;

    await _salesmanCollection.doc(salesman.id).update(updateData);
  }

  Future<void> deleteSalesman(String salesmanId) async {
    await _salesmanCollection.doc(salesmanId).delete();
  }

  // FIX: Renamed _uploadImage to uploadImage and made it public for use in other services if needed.
  Future<String?> uploadImage(File imageFile, String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
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