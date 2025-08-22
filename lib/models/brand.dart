import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Brand {
  final String id;
  final String name;
  final double pricePerUnit;
  final String icon;
  bool isFrozen;
  final Timestamp createdAt;

  Brand({
    required this.id,
    required this.name,
    required this.pricePerUnit,
    this.icon = '',
    this.isFrozen = false,
    required this.createdAt,
  });

  factory Brand.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Brand(
      id: snapshot.id,
      name: data?['name'] ?? '',
      pricePerUnit: (data?['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      icon: data?['icon'] ?? '',
      isFrozen: data?['isFrozen'] ?? false,
      createdAt: data?['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "pricePerUnit": pricePerUnit,
      "icon": icon,
      "isFrozen": isFrozen,
      "createdAt": createdAt,
    };
  }

  // FIX: Added the copyWith method
  Brand copyWith({
    String? id,
    String? name,
    double? pricePerUnit,
    String? icon,
    bool? isFrozen,
    Timestamp? createdAt,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      icon: icon ?? this.icon,
      isFrozen: isFrozen ?? this.isFrozen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Brand && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  static List<Brand> get dummyBrands => [
    Brand(id: 'b001', name: 'Marlboro', pricePerUnit: 250.0, icon: '🚭', createdAt: Timestamp.now()),
    Brand(id: 'b002', name: 'Dunhill', pricePerUnit: 280.0, icon: '🚬', createdAt: Timestamp.now()),
    Brand(id: 'b003', name: 'Capstan', pricePerUnit: 180.0, icon: '📦', createdAt: Timestamp.now()),
    Brand(id: 'b004', name: 'Gold Leaf', pricePerUnit: 260.0, icon: '✈️', createdAt: Timestamp.now()),
    Brand(id: 'b005', name: 'Pine', pricePerUnit: 150.0, icon: '🍎', createdAt: Timestamp.now(), isFrozen: true),
    Brand(id: 'b006', name: 'Morven Gold', pricePerUnit: 220.0, icon: '⭐', createdAt: Timestamp.now()),
    Brand(id: 'b007', name: 'K2', pricePerUnit: 190.0, icon: '🔥', createdAt: Timestamp.now()),
  ];
}