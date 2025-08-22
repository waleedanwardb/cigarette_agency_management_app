import 'package:flutter/material.dart'; // For TextDecoration if status changes

class Arrear {
  final String id;
  final String salesmanId;
  final String salesmanName;
  final DateTime dateIncurred;
  final double amount;
  final String description; // Reason for arrear
  String status; // 'Outstanding', 'Cleared'
  DateTime? clearanceDate;
  String? clearanceDescription;

  Arrear({
    required this.id,
    required this.salesmanId,
    required this.salesmanName,
    required this.dateIncurred,
    required this.amount,
    this.description = '',
    this.status = 'Outstanding',
    this.clearanceDate,
    this.clearanceDescription,
  });

  // Helper to create a copy with updated values
  Arrear copyWith({
    String? status,
    DateTime? clearanceDate,
    String? clearanceDescription,
  }) {
    return Arrear(
      id: id,
      salesmanId: salesmanId,
      salesmanName: salesmanName,
      dateIncurred: dateIncurred,
      amount: amount,
      description: description,
      status: status ?? this.status,
      clearanceDate: clearanceDate ?? this.clearanceDate,
      clearanceDescription: clearanceDescription ?? this.clearanceDescription,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Arrear && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  // Dummy arrears for demonstration
  static List<Arrear> get dummyArrears => [
    Arrear(
      id: 'arr001',
      salesmanId: 's001',
      salesmanName: 'Ahmed Khan',
      dateIncurred: DateTime(2025, 7, 20),
      amount: 2500.0,
      description: 'Cash left from morning sales',
    ),
    Arrear(
      id: 'arr002',
      salesmanId: 's002',
      salesmanName: 'Sara Ali',
      dateIncurred: DateTime(2025, 7, 18),
      amount: 1000.0,
      description: 'Pending collection from shop X',
      status: 'Cleared',
      clearanceDate: DateTime(2025, 7, 19),
      clearanceDescription: 'Collected next day',
    ),
    Arrear(
      id: 'arr003',
      salesmanId: 's001',
      salesmanName: 'Ahmed Khan',
      dateIncurred: DateTime(2025, 7, 15),
      amount: 3000.0,
      description: 'Collection from large order',
    ),
    Arrear(
      id: 'arr004',
      salesmanId: 's003',
      salesmanName: 'Usman Tariq',
      dateIncurred: DateTime(2025, 7, 22),
      amount: 1500.0,
      description: 'Cash for afternoon deliveries',
    ),
  ];
}