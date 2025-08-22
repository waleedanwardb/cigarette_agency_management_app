// lib/models/mt_claim.dart
import 'package:flutter/material.dart';

class MTClaim {
  final String id;
  final String type; // e.g., 'Lighter Gift', 'Empty Box Exchange', 'Cash Gift'
  final String description;
  final double quantity; // e.g., number of lighters, number of empty boxes
  final double value; // Monetary value of the claim
  final DateTime dateClaimed;
  String status; // 'Pending Audit', 'Cleared', 'Rejected'
  DateTime? auditClearanceDate;
  String? auditorNotes;

  MTClaim({
    required this.id,
    required this.type,
    required this.description,
    required this.quantity,
    required this.value,
    required this.dateClaimed,
    this.status = 'Pending Audit',
    this.auditClearanceDate,
    this.auditorNotes,
  });

  MTClaim copyWith({
    String? id,
    String? type,
    String? description,
    double? quantity,
    double? value,
    DateTime? dateClaimed,
    String? status,
    DateTime? auditClearanceDate,
    String? auditorNotes,
  }) {
    return MTClaim(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      value: value ?? this.value,
      dateClaimed: dateClaimed ?? this.dateClaimed,
      status: status ?? this.status,
      auditClearanceDate: auditClearanceDate ?? this.auditClearanceDate,
      auditorNotes: auditorNotes ?? this.auditorNotes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is MTClaim && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  static List<MTClaim> get dummyMTClaims => [
    MTClaim(
      id: 'mtc001',
      type: 'Lighter Gift',
      description: 'Lighters from July promotional stock',
      quantity: 50.0,
      value: 5000.0,
      dateClaimed: DateTime(2025, 7, 25),
    ),
    MTClaim(
      id: 'mtc002',
      type: 'Empty Box Exchange',
      description: '100 empty packs returned for credit',
      quantity: 100.0,
      value: 2000.0,
      dateClaimed: DateTime(2025, 7, 20),
      status: 'Cleared',
      auditClearanceDate: DateTime(2025, 7, 21),
      auditorNotes: 'Audited and approved.',
    ),
    MTClaim(
      id: 'mtc003',
      type: 'Cash Gift',
      description: 'Promotional cash gifts from Red Label packs',
      quantity: 15.0,
      value: 1500.0,
      dateClaimed: DateTime(2025, 7, 18),
      status: 'Pending Audit',
    ),
  ];
}