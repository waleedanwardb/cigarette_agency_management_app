// lib/models/brand.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Brand {
  final String id;
  final String name;
  final String icon;
  final bool isFrozen;
  final String imageUrl;

  const Brand({
    required this.id,
    required this.name,
    required this.icon,
    required this.isFrozen,
    required this.imageUrl,
  });

  // Factory constructor to create a Brand object from a Firestore document
  factory Brand.fromMap(Map<String, dynamic> data, String id) {
    return Brand(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      isFrozen: data['isFrozen'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  // Method to convert a Brand object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'isFrozen': isFrozen,
      'imageUrl': imageUrl,
    };
  }

  // A helper method for updating a brand with new values
  Brand copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isFrozen,
    String? imageUrl,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isFrozen: isFrozen ?? this.isFrozen,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}