// lib/services/company_claim_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:flutter/material.dart';

class CompanyClaimService {
  final CollectionReference _claimsCollection =
  FirebaseFirestore.instance.collection('company_claims');

  Stream<List<CompanyClaim>> getCompanyClaims() {
    return _claimsCollection.orderBy('dateIncurred', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CompanyClaim.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> addCompanyClaim(CompanyClaim claim) async {
    await _claimsCollection.add(claim.toFirestore());
  }

  Future<void> updateCompanyClaim(CompanyClaim claim) async {
    await _claimsCollection.doc(claim.id).update(claim.toFirestore());
  }

  Future<void> deleteCompanyClaim(String claimId) async {
    debugPrint('Attempting to delete claim with ID: $claimId from collection: company_claims');
    await _claimsCollection.doc(claimId).delete();
  }
}