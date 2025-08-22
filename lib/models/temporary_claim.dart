import 'package:flutter/material.dart'; // For TextDecoration if status changes

class TemporaryClaim {
  final String id;
  final String description;
  final double amount;
  String status; // 'Pending', 'Cleared', 'Rejected'
  final DateTime dateIncurred;
  DateTime? clearanceDate;
  String? clearanceDescription;

  TemporaryClaim({
    required this.id,
    required this.description,
    required this.amount,
    required this.status,
    required this.dateIncurred,
    this.clearanceDate,
    this.clearanceDescription,
  });

  // Helper to create a copy with updated status/clearance info
  TemporaryClaim copyWith({
    String? status,
    DateTime? clearanceDate,
    String? clearanceDescription,
  }) {
    return TemporaryClaim(
      id: id,
      description: description,
      amount: amount,
      status: status ?? this.status,
      dateIncurred: dateIncurred,
      clearanceDate: clearanceDate ?? this.clearanceDate,
      clearanceDescription: clearanceDescription ?? this.clearanceDescription,
    );
  }

  // Override == and hashCode for correct comparison in lists
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is TemporaryClaim && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  // Dummy claims for demonstration
  static List<TemporaryClaim> get dummyTemporaryClaims => [
    TemporaryClaim(
      id: 'tc001',
      description: 'Emergency travel expense - Salesman B',
      amount: 1500.0,
      status: 'Pending',
      dateIncurred: DateTime(2025, 7, 20),
    ),
    TemporaryClaim(
      id: 'tc002',
      description: 'Small office supplies purchase',
      amount: 300.0,
      status: 'Cleared',
      dateIncurred: DateTime(2025, 7, 18),
      clearanceDate: DateTime(2025, 7, 19),
      clearanceDescription: 'Approved by Manager',
    ),
    TemporaryClaim(
      id: 'tc003',
      description: 'Minor vehicle repair (local)',
      amount: 700.0,
      status: 'Pending',
      dateIncurred: DateTime(2025, 7, 10),
    ),
  ];
}