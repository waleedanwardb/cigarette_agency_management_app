// lib/models/arrear.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Arrear {
  final String id;
  final String salesmanId;
  final String salesmanName;
  final DateTime dateIncurred;
  final double amount;
  final String description;
  final String status; // e.g., 'Outstanding', 'Cleared'
  final DateTime? clearanceDate;
  final String? clearanceDescription;

  Arrear({
    required this.id,
    required this.salesmanId,
    required this.salesmanName,
    required this.dateIncurred,
    required this.amount,
    required this.description,
    this.status = 'Outstanding',
    this.clearanceDate,
    this.clearanceDescription,
  });

  factory Arrear.fromFirestore(Map<String, dynamic> data, String id) {
    return Arrear(
      id: id,
      salesmanId: data['salesmanId'] ?? '',
      salesmanName: data['salesmanName'] ?? '',
      dateIncurred: (data['dateIncurred'] as Timestamp).toDate(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      status: data['status'] ?? 'Outstanding',
      clearanceDate: (data['clearanceDate'] as Timestamp?)?.toDate(),
      clearanceDescription: data['clearanceDescription'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'dateIncurred': Timestamp.fromDate(dateIncurred),
      'amount': amount,
      'description': description,
      'status': status,
      if (clearanceDate != null) 'clearanceDate': Timestamp.fromDate(clearanceDate!),
      if (clearanceDescription != null) 'clearanceDescription': clearanceDescription,
    };
  }

  Arrear copyWith({
    String? id,
    String? salesmanId,
    String? salesmanName,
    DateTime? dateIncurred,
    double? amount,
    String? description,
    String? status,
    DateTime? clearanceDate,
    String? clearanceDescription,
  }) {
    return Arrear(
      id: id ?? this.id,
      salesmanId: salesmanId ?? this.salesmanId,
      salesmanName: salesmanName ?? this.salesmanName,
      dateIncurred: dateIncurred ?? this.dateIncurred,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      clearanceDate: clearanceDate ?? this.clearanceDate,
      clearanceDescription: clearanceDescription ?? this.clearanceDescription,
    );
  }
}