// lib/models/scheme.dart
class Scheme {
  final String id;
  final String name;
  final String type; // e.g., 'FixedAmountPerPack', 'PercentageOff'
  final double amount; // The per-pack value or percentage
  final bool isActive;
  final DateTime validFrom;
  final DateTime validTo;
  final String companyName; // NEW FIELD
  final String productName; // NEW FIELD (more specific than applicableProducts)
  final String description; // Renamed from original to be more explicit
  final String applicableProducts; // Keep as general description/fallback

  Scheme({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.isActive,
    required this.validFrom,
    required this.validTo,
    required this.companyName,
    required this.productName,
    this.description = '',
    this.applicableProducts = 'Not specified',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Scheme && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  static List<Scheme> get dummySchemes => [
    Scheme(
      id: 's1',
      name: 'Summer Saver',
      type: 'FixedAmountPerPack',
      amount: 10.0,
      isActive: true,
      validFrom: DateTime(2025, 7, 1),
      validTo: DateTime(2025, 8, 31),
      companyName: 'ABC Cigars',
      productName: 'Marlboro Red 20s',
      description: 'PKR 10 off per pack in summer.',
      applicableProducts: 'Marlboro Red Variants',
    ),
    Scheme(
      id: 's2',
      name: 'Monsoon Deal',
      type: 'FixedAmountPerPack',
      amount: 5.0,
      isActive: true,
      validFrom: DateTime(2025, 7, 15),
      validTo: DateTime(2025, 9, 15),
      companyName: 'XYZ Tobacco',
      productName: 'Dunhill Blue 20s',
      description: 'PKR 5 off per pack for monsoon.',
      applicableProducts: 'Dunhill Blue Variants',
    ),
    Scheme(
      id: 's3',
      name: 'Loyalty Bonus',
      type: 'FixedAmountPerPack',
      amount: 2.0,
      isActive: false,
      validFrom: DateTime(2025, 1, 1),
      validTo: DateTime(2025, 12, 31),
      companyName: 'Universal Smokes',
      productName: 'Capstan Filter 20s',
      description: 'PKR 2 off for loyal customers.',
      applicableProducts: 'All Capstan Packs',
    ),
  ];
}