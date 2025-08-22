// lib/models/company_claim.dart
import 'package:flutter/material.dart'; // For TextDecoration

class CompanyClaim {
  final String id;
  final String type; // e.g., 'Scheme Amount', 'Car Maintenance', 'Salesman Salary', 'Scheme Amount (Return)'
  final String description; // Detailed description for display
  final double amount;
  String status; // 'Pending', 'Paid'
  final DateTime dateIncurred;
  DateTime? clearanceDate; // When the company cleared it
  String? clearanceDescription; // Custom description for clearance

  // Specific fields for scheme claims
  final String? brandName;
  final String? productName;
  final List<String>? schemeNames;
  final double? packsAffected; // Changed to double for consistency with other amounts, if packs can be fractional
  final String? companyName; // NEW: Company associated with this claim

  CompanyClaim({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
    required this.dateIncurred,
    this.clearanceDate,
    this.clearanceDescription,
    this.brandName,
    this.productName,
    this.schemeNames,
    this.packsAffected,
    this.companyName, // Added to constructor
  });

  // Method to mark as cleared
  // Note: This modifies the object directly. If using immutable state, you'd use copyWith.
  void markAsCleared({required DateTime date, String? description}) {
    status = 'Paid';
    clearanceDate = date;
    clearanceDescription = description;
  }

  // Helper to create a copy with updated status/clearance info (good for immutable state)
  CompanyClaim copyWith({
    String? status,
    DateTime? clearanceDate,
    String? clearanceDescription,
  }) {
    return CompanyClaim(
      id: id,
      type: type,
      description: description,
      amount: amount,
      status: status ?? this.status,
      dateIncurred: dateIncurred,
      clearanceDate: clearanceDate ?? this.clearanceDate,
      clearanceDescription: clearanceDescription ?? this.clearanceDescription,
      brandName: brandName,
      productName: productName,
      schemeNames: schemeNames,
      packsAffected: packsAffected,
      companyName: companyName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is CompanyClaim && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;
}

// Dummy Global list for company claims (for demonstration)
List<CompanyClaim> globalCompanyClaims = [
  CompanyClaim(
    id: 'cc001',
    type: 'Car Maintenance',
    description: 'Q2 Vehicle Service - Car A',
    amount: 15000.0,
    status: 'Pending',
    dateIncurred: DateTime(2025, 6, 30),
  ),
  CompanyClaim(
    id: 'cc002',
    type: 'Salesman Salary',
    description: 'June 2025 - Salesman B Salary',
    amount: 30000.0,
    status: 'Paid',
    dateIncurred: DateTime(2025, 6, 25),
    clearanceDate: DateTime(2025, 7, 1),
    clearanceDescription: 'Monthly payroll',
  ),
];