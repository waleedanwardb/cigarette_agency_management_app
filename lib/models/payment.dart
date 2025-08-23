// lib/models/payment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String type; // 'Salesman Payment' or 'Company Payment'
  final String referenceId; // salesmanId or companyInvoiceId
  final String description;
  final double amount;
  final Timestamp date;

  Payment({
    required this.id,
    required this.type,
    required this.referenceId,
    required this.description,
    required this.amount,
    required this.date,
  });

  factory Payment.fromFirestore(Map<String, dynamic> data, String id) {
    return Payment(
      id: id,
      type: data['type'] ?? '',
      referenceId: data['referenceId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: data['date'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'referenceId': referenceId,
      'description': description,
      'amount': amount,
      'date': date,
    };
  }
}