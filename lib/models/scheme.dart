// lib/models/scheme.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Scheme {
  final String id;
  final String name;
  final String type; // e.g., 'FixedAmountPerPack', 'PercentageOff'
  final double amount; // The per-pack value or percentage
  final bool isActive;
  final DateTime validFrom;
  final DateTime validTo;
  final String companyName;
  final String productName;
  final String description;
  final String applicableProducts;

  Scheme({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.isActive,
    required this.validFrom,
    required this.validTo,
    required this.companyName,
    required this.productName,
    this.description = '',
    this.applicableProducts = 'Not specified',
  });

  // Factory constructor to create a Scheme object from a Firestore document
  factory Scheme.fromMap(Map<String, dynamic> data, String id) {
    return Scheme(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] ?? false,
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp).toDate(),
      companyName: data['companyName'] ?? '',
      productName: data['productName'] ?? '',
      description: data['description'] ?? '',
      applicableProducts: data['applicableProducts'] ?? '',
    );
  }

  // Method to convert a Scheme object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'amount': amount,
      'isActive': isActive,
      'validFrom': validFrom,
      'validTo': validTo,
      'companyName': companyName,
      'productName': productName,
      'description': description,
      'applicableProducts': applicableProducts,
    };
  }

  // The rest of your existing code remains unchanged below this line.
  // ...
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Scheme && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  static List<Scheme> get dummySchemes => [
    Scheme(
      id: 's1',
      name: 'Summer Saver',
      type: 'FixedAmountPerPack',
      amount: 10.0,
      isActive: true,
      validFrom: DateTime(2025, 7, 1),
      validTo: DateTime(2025, 8, 31),
      companyName: 'ABC Cigars',
      productName: 'Marlboro Red 20s',
      description: 'PKR 10 off per pack in summer.',
      applicableProducts: 'Marlboro Red Variants',
    ),
    Scheme(
      id: 's2',
      name: 'Monsoon Deal',
      type: 'FixedAmountPerPack',
      amount: 5.0,
      isActive: true,
      validFrom: DateTime(2025, 7, 15),
      validTo: DateTime(2025, 9, 15),
      companyName: 'XYZ Tobacco',
      productName: 'Dunhill Blue 20s',
      description: 'PKR 5 off per pack for monsoon.',
      applicableProducts: 'Dunhill Blue Variants',
    ),
    Scheme(
      id: 's3',
      name: 'Loyalty Bonus',
      type: 'FixedAmountPerPack',
      amount: 2.0,
      isActive: false,
      validFrom: DateTime(2025, 1, 1),
      validTo: DateTime(2025, 12, 31),
      companyName: 'Universal Smokes',
      productName: 'Capstan Filter 20s',
      description: 'PKR 2 off for loyal customers.',
      applicableProducts: 'All Capstan Packs',
    ),
  ];
}