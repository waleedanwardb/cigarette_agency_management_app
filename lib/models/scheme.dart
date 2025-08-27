// lib/models/scheme.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Scheme {
  final String id;
  final String name;
  final String description;
  final double amount;
  final String productId;
  final bool isActive;

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.productId,
    this.isActive = true,
  });

  // Factory constructor to create a Scheme from a Firestore document
  factory Scheme.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Scheme(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      productId: data['productId'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  // Method to convert a Scheme to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'amount': amount,
      'productId': productId,
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}