// lib/models/company_claim.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyClaim {
  final String id;
  final String type;
  final String description;
  final double amount;
  final String status;
  final DateTime dateIncurred;
  final String? brandName;
  final String? productName;
  final List<String>? schemeNames;
  final double? packsAffected;
  final String? companyName;

  CompanyClaim({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
    required this.dateIncurred,
    this.brandName,
    this.productName,
    this.schemeNames,
    this.packsAffected,
    this.companyName,
  });

  factory CompanyClaim.fromFirestore(Map<String, dynamic> data, String id) {
    return CompanyClaim(
      id: id,
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? '',
      dateIncurred: (data['dateIncurred'] as Timestamp).toDate(),
      brandName: data['brandName'],
      productName: data['productName'],
      schemeNames: (data['schemeNames'] as List?)?.map((e) => e.toString()).toList(),
      packsAffected: (data['packsAffected'] as num?)?.toDouble(),
      companyName: data['companyName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'description': description,
      'amount': amount,
      'status': status,
      'dateIncurred': Timestamp.fromDate(dateIncurred),
      if (brandName != null) 'brandName': brandName,
      if (productName != null) 'productName': productName,
      if (schemeNames != null) 'schemeNames': schemeNames,
      if (packsAffected != null) 'packsAffected': packsAffected,
      if (companyName != null) 'companyName': companyName,
    };
  }

  CompanyClaim copyWith({
    String? id,
    String? type,
    String? description,
    double? amount,
    String? status,
    DateTime? dateIncurred,
    String? brandName,
    String? productName,
    List<String>? schemeNames,
    double? packsAffected,
    String? companyName,
  }) {
    return CompanyClaim(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dateIncurred: dateIncurred ?? this.dateIncurred,
      brandName: brandName ?? this.brandName,
      productName: productName ?? this.productName,
      schemeNames: schemeNames ?? this.schemeNames,
      packsAffected: packsAffected ?? this.packsAffected,
      companyName: companyName ?? this.companyName,
    );
  }
}