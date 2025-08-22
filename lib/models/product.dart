import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String brand;
  final String brandId;
  final int stockQuantity;
  bool isFrozen;
  final Timestamp createdAt;

  Product({
    required this.id,
    required this.name,
    this.imageUrl = '',
    required this.price,
    required this.brand,
    this.brandId = '',
    required this.stockQuantity,
    this.isFrozen = false,
    required this.createdAt,
  });

  bool get inStock => stockQuantity > 0;

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Product(
      id: snapshot.id,
      name: data?['name'] ?? '',
      imageUrl: data?['imageUrl'] ?? '',
      price: (data?['price'] as num?)?.toDouble() ?? 0.0,
      brand: data?['brandName'] ?? '',
      brandId: data?['brandId'] ?? '',
      stockQuantity: (data?['stockQuantity'] as num?)?.toInt() ?? 0,
      isFrozen: data?['isFrozen'] ?? false,
      createdAt: data?['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "imageUrl": imageUrl,
      "price": price,
      "brandName": brand,
      "brandId": brandId,
      "stockQuantity": stockQuantity,
      "isFrozen": isFrozen,
      "createdAt": createdAt,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    String? brand,
    String? brandId,
    int? stockQuantity,
    bool? isFrozen,
    Timestamp? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      brand: brand ?? this.brand,
      brandId: brandId ?? this.brandId,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isFrozen: isFrozen ?? this.isFrozen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Product && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  static List<Product> get dummyProducts => [
    Product(id: 'p001', name: 'Red 20s', imageUrl: 'assets/product_marlboro_red.png', price: 250.00, brand: 'Marlboro', brandId: 'b001', stockQuantity: 150, createdAt: Timestamp.now()),
    Product(id: 'p002', name: 'Blue 20s', imageUrl: 'assets/product_dunhill_blue.png', price: 280.00, brand: 'Dunhill', brandId: 'b002', stockQuantity: 80, createdAt: Timestamp.now()),
    Product(id: 'p003', name: 'Filter 20s', imageUrl: 'assets/product_capstan.png', price: 180.00, brand: 'Capstan', brandId: 'b003', stockQuantity: 200, createdAt: Timestamp.now()),
    Product(id: 'p004', name: 'Green 20s', imageUrl: 'assets/product_gold_leaf.png', price: 260.00, brand: 'Gold Leaf', brandId: 'b004', stockQuantity: 120, createdAt: Timestamp.now()),
    Product(id: 'p005', name: 'Menthol 20s', imageUrl: 'assets/product_pine.png', price: 150.00, brand: 'Pine', brandId: 'b005', stockQuantity: 0, isFrozen: true, createdAt: Timestamp.now()),
    Product(id: 'p006', name: 'Morven Gold 20s', imageUrl: 'assets/product_morven_gold.png', price: 220.00, brand: 'Morven Gold', brandId: 'b006', stockQuantity: 90, createdAt: Timestamp.now()),
    Product(id: 'p007', name: 'K2 Slims', imageUrl: 'assets/product_k2.png', price: 190.00, brand: 'K2', brandId: 'b007', stockQuantity: 60, createdAt: Timestamp.now()),
  ];
}