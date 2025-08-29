// lib/models/salesman.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Salesman {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String imageUrl;
  final String idCardNumber;
  final String contactNumber;
  final String emergencyContactNumber;
  final String? idCardFrontUrl;
  final String? idCardBackUrl;
  final bool isFrozen;

  Salesman({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.imageUrl = '',
    this.idCardNumber = '',
    this.contactNumber = '',
    this.emergencyContactNumber = '',
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.isFrozen = false,
  });

  factory Salesman.fromFirestore(DocumentSnapshot doc, [SnapshotOptions? options]) {
    final data = doc.data() as Map<String, dynamic>;
    return Salesman(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      idCardNumber: data['idCardNumber'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      emergencyContactNumber: data['emergencyContactNumber'] ?? '',
      idCardFrontUrl: data['idCardFrontUrl'] ?? '',
      idCardBackUrl: data['idCardBackUrl'] ?? '',
      isFrozen: data['isFrozen'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'imageUrl': imageUrl,
      'idCardNumber': idCardNumber,
      'contactNumber': contactNumber,
      'emergencyContactNumber': emergencyContactNumber,
      'idCardFrontUrl': idCardFrontUrl,
      'idCardBackUrl': idCardBackUrl,
      'isFrozen': isFrozen,
    };
  }

  Salesman copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? address,
    String? imageUrl,
    String? idCardNumber,
    String? contactNumber,
    String? emergencyContactNumber,
    String? idCardFrontUrl,
    String? idCardBackUrl,
    bool? isFrozen,
  }) {
    return Salesman(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      idCardFrontUrl: idCardFrontUrl ?? this.idCardFrontUrl,
      idCardBackUrl: idCardBackUrl ?? this.idCardBackUrl,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }
}
