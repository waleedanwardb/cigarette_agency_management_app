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
  final bool isFrozen;

  Salesman({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.idCardNumber = '',
    this.address = '',
    this.contactNumber = '',
    this.emergencyContactNumber = '',
    this.isFrozen = false,
  });

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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "profileImageUrl": imageUrl,
      "idCardNumber": idCardNumber,
      "address": address,
      "contactNumber": contactNumber,
      "emergencyContactNumber": emergencyContactNumber,
      "isFrozen": isFrozen,
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
    );
  }
}