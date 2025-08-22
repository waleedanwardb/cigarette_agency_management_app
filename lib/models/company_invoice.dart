import 'package:flutter/material.dart'; // For TextDecoration if status changes

class CompanyInvoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final double totalAmount;
  double amountPaid; // This will change as payments are made
  String status; // 'Due', 'Partially Paid', 'Paid'
  final String stockReference; // e.g., "STK-010" or "Batch #XYZ"

  CompanyInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.totalAmount,
    this.amountPaid = 0.0,
    this.status = 'Due',
    required this.stockReference,
  });

  double get remainingAmount => totalAmount - amountPaid;

  // Helper to create a copy with updated values (for immutable state management)
  CompanyInvoice copyWith({
    double? amountPaid,
    String? status,
  }) {
    return CompanyInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      totalAmount: totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      stockReference: stockReference,
    );
  }

  // Dummy invoices for demonstration
  static List<CompanyInvoice> get dummyInvoices => [
    CompanyInvoice(
      id: 'inv001',
      invoiceNumber: 'INV-2025-001',
      invoiceDate: DateTime(2025, 7, 10),
      totalAmount: 1000000.0,
      amountPaid: 500000.0,
      status: 'Partially Paid',
      stockReference: 'Batch A-123',
    ),
    CompanyInvoice(
      id: 'inv002',
      invoiceDate: DateTime(2025, 7, 15),
      invoiceNumber: 'INV-2025-002',
      totalAmount: 750000.0,
      amountPaid: 0.0,
      status: 'Due',
      stockReference: 'Batch B-456',
    ),
    CompanyInvoice(
      id: 'inv003',
      invoiceDate: DateTime(2025, 6, 20),
      invoiceNumber: 'INV-2025-003',
      totalAmount: 500000.0,
      amountPaid: 500000.0,
      status: 'Paid',
      stockReference: 'Batch C-789',
    ),
  ];
}