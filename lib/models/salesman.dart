// lib/models/salesman.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Salesman {
  final String id;
  final String name;
  final String imageUrl;
  final String idCardNumber;
  final String address;
  final String contactNumber;
  final String emergencyContactNumber;
  bool isFrozen;
  final Timestamp createdAt;

  Salesman({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.idCardNumber = '',
    this.address = '',
    this.contactNumber = '',
    this.emergencyContactNumber = '',
    this.isFrozen = false,
    required this.createdAt,
  });

  // FIX: Added the 'fromFirestore' factory constructor
  factory Salesman.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Salesman(
      id: snapshot.id,
      name: data?['name'] ?? '',
      imageUrl: data?['profileImageUrl'] ?? '',
      idCardNumber: data?['idCardNumber'] ?? '',
      address: data?['address'] ?? '',
      contactNumber: data?['contactNumber'] ?? '',
      emergencyContactNumber: data?['emergencyContactNumber'] ?? '',
      isFrozen: data?['isFrozen'] ?? false,
      createdAt: data?['createdAt'] ?? Timestamp.now(),
    );
  }

  // FIX: Added the 'toFirestore' method
  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "profileImageUrl": imageUrl,
      "idCardNumber": idCardNumber,
      "address": address,
      "contactNumber": contactNumber,
      "emergencyContactNumber": emergencyContactNumber,
      "isFrozen": isFrozen,
      "createdAt": createdAt,
    };
  }

  Salesman copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? idCardNumber,
    String? address,
    String? contactNumber,
    String? emergencyContactNumber,
    bool? isFrozen,
    Timestamp? createdAt,
  }) {
    return Salesman(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      isFrozen: isFrozen ?? this.isFrozen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<Salesman> get dummySalesmen => [
    Salesman(id: 's001', name: 'Ahmed Khan', imageUrl: 'assets/salesman_ahmed.png', idCardNumber: '123-456-789', address: '123 Main St', contactNumber: '03001234567', emergencyContactNumber: '03011234567', createdAt: Timestamp.now()),
    Salesman(id: 's002', name: 'Sara Ali', imageUrl: 'assets/salesman_sara.png', idCardNumber: '987-654-321', address: '456 Oak Ave', contactNumber: '03021234567', emergencyContactNumber: '03031234567', isFrozen: true, createdAt: Timestamp.now()),
    Salesman(id: 's003', name: 'Usman Tariq', imageUrl: 'assets/salesman_usman.png', idCardNumber: '111-222-333', address: '789 Pine Ln', contactNumber: '03041234567', emergencyContactNumber: '03051234567', createdAt: Timestamp.now()),
    Salesman(id: 's004', name: 'Fatima Zahra', imageUrl: 'assets/salesman_fatima.png', idCardNumber: '444-555-666', address: '101 Elm Blvd', contactNumber: '03061234567', emergencyContactNumber: '03071234567', createdAt: Timestamp.now()),
    Salesman(id: 's005', name: 'Ali Raza', imageUrl: 'assets/salesman_ali.png', idCardNumber: '777-888-999', address: '202 Birch Rd', contactNumber: '03081234567', emergencyContactNumber: '03091234567', createdAt: Timestamp.now()),
  ];
}