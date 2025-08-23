// lib/models/salesman_account_transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SalesmanAccountTransaction {
  final String id;
  final String salesmanId;
  final String description;
  final Timestamp date; // Use Timestamp for Firestore compatibility
  final String type; // e.g., 'Stock Out', 'Cash Received', 'Salary Paid', 'Advance'
  final String? productName;
  final String? brandName;
  final double? stockOutQuantity;
  final double? stockReturnQuantity;
  final double? cashReceived;
  final String? notes; // Renamed from description in old code
  final List<String>? appliedSchemeNames;
  final double? totalSchemeDiscount;
  final double? calculatedPrice;
  final double? grossPrice;

  SalesmanAccountTransaction({
    required this.id,
    required this.salesmanId,
    required this.description,
    required this.date,
    required this.type,
    this.productName,
    this.brandName,
    this.stockOutQuantity,
    this.stockReturnQuantity,
    this.cashReceived,
    this.notes,
    this.appliedSchemeNames,
    this.totalSchemeDiscount,
    this.calculatedPrice,
    this.grossPrice,
  });

  // Factory constructor to create a SalesmanAccountTransaction from a Firestore document.
  factory SalesmanAccountTransaction.fromFirestore(Map<String, dynamic> data, String id) {
    return SalesmanAccountTransaction(
      id: id,
      salesmanId: data['salesmanId'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      type: data['type'] ?? '',
      productName: data['productName'],
      brandName: data['brandName'],
      stockOutQuantity: (data['stockOutQuantity'] as num?)?.toDouble(),
      stockReturnQuantity: (data['stockReturnQuantity'] as num?)?.toDouble(),
      cashReceived: (data['cashReceived'] as num?)?.toDouble(),
      notes: data['notes'],
      appliedSchemeNames: (data['appliedSchemeNames'] as List<dynamic>?)?.map((item) => item as String).toList(),
      totalSchemeDiscount: (data['totalSchemeDiscount'] as num?)?.toDouble(),
      calculatedPrice: (data['calculatedPrice'] as num?)?.toDouble(),
      grossPrice: (data['grossPrice'] as num?)?.toDouble(),
    );
  }

  // Method to convert a SalesmanAccountTransaction object into a map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'salesmanId': salesmanId,
      'description': description,
      'date': date,
      'type': type,
      if (productName != null) 'productName': productName,
      if (brandName != null) 'brandName': brandName,
      if (stockOutQuantity != null) 'stockOutQuantity': stockOutQuantity,
      if (stockReturnQuantity != null) 'stockReturnQuantity': stockReturnQuantity,
      if (cashReceived != null) 'cashReceived': cashReceived,
      if (notes != null) 'notes': notes,
      if (appliedSchemeNames != null) 'appliedSchemeNames': appliedSchemeNames,
      if (totalSchemeDiscount != null) 'totalSchemeDiscount': totalSchemeDiscount,
      if (calculatedPrice != null) 'calculatedPrice': calculatedPrice,
      if (grossPrice != null) 'grossPrice': grossPrice,
    };
  }

// NOTE: The dummyTransactions list in the original file had different fields.
// I've kept it as a placeholder but you should use the real data from Firestore.
// The old model was not designed for a transaction ledger and was a simple list.
// You will need to update the `SalesmanStockDetailScreen` again
// to properly use the new model's fields, as the current code
// is still using some of the old fields like `cashGiven` and `stockGivenAmount`.
}