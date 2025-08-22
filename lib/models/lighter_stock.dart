// lib/models/lighter_stock.dart
import 'package:flutter/material.dart';

class LighterStock {
  final String id;
  final String name; // e.g., 'Standard Lighter', 'Branded Lighter'
  double currentStock;
  final String description;
  final DateTime lastReceived;
  final DateTime lastIssued;

  LighterStock({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.description,
    required this.lastReceived,
    required this.lastIssued,
  });

  LighterStock copyWith({
    String? id,
    String? name,
    double? currentStock,
    String? description,
    DateTime? lastReceived,
    DateTime? lastIssued,
  }) {
    return LighterStock(
      id: id ?? this.id,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      description: description ?? this.description,
      lastReceived: lastReceived ?? this.lastReceived,
      lastIssued: lastIssued ?? this.lastIssued,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is LighterStock && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  static List<LighterStock> get dummyLighterStocks => [
    LighterStock(
      id: 'lts001',
      name: 'Standard Lighter',
      description: 'Basic disposable lighters for trade.',
      currentStock: 250.0,
      lastReceived: DateTime(2025, 7, 20),
      lastIssued: DateTime(2025, 7, 24),
    ),
    LighterStock(
      id: 'lts002',
      name: 'Branded Lighter',
      description: 'Marlboro branded lighters for promotion.',
      currentStock: 150.0,
      lastReceived: DateTime(2025, 7, 15),
      lastIssued: DateTime(2025, 7, 25),
    ),
    LighterStock(
      id: 'lts003',
      name: 'Refillable Lighter',
      description: 'High-quality lighters for special schemes.',
      currentStock: 50.0,
      lastReceived: DateTime(2025, 7, 10),
      lastIssued: DateTime(2025, 7, 15),
    ),
  ];
}