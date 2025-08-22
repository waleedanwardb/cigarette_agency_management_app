import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/models/brand.dart';
import 'package:cigarette_agency_management_app/services/product_service.dart';

class BrandProductsListScreen extends StatelessWidget {
  final Brand brand;

  const BrandProductsListScreen({
    super.key,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${brand.name} Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: productService.getProducts().where((event) => event.any((product) => product.brandId == brand.id)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No products found for ${brand.name}.'));
          }

          final products = snapshot.data!.where((product) => product.brandId == brand.id).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: product.isFrozen ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none),
                child: InkWell(
                  onTap: () {},
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                                  : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(product.brand, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                Text('PKR ${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                if (product.inStock)
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)), child: Text('Stock: ${product.stockQuantity}', style: TextStyle(color: Colors.green[700], fontSize: 10)))
                                else
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)), child: Text('Out of Stock', style: TextStyle(color: Colors.red[700], fontSize: 10))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (product.isFrozen)
                        const Positioned(top: 8, right: 8, child: Icon(Icons.lock, color: Colors.blue, size: 24)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}