// lib/UI/screens/scheme_management/scheme_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/services/scheme_service.dart';
import 'package:cigarette_agency_management_app/services/product_service.dart';
import 'add_edit_scheme_screen.dart';

class SchemeManagementScreen extends StatelessWidget {
  const SchemeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schemeService = Provider.of<SchemeService>(context);
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AddEditSchemeScreen(),
              ));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Scheme>>(
        stream: schemeService.getSchemes(),
        builder: (context, schemeSnapshot) {
          if (schemeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!schemeSnapshot.hasData || schemeSnapshot.data!.isEmpty) {
            return const Center(child: Text('No schemes available.'));
          }
          final schemes = schemeSnapshot.data!;

          return StreamBuilder<List<Product>>(
            stream: productService.getProducts(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!productSnapshot.hasData ||
                  productSnapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Product data is not available.'));
              }
              final products = productSnapshot.data!;

              return ListView.builder(
                itemCount: schemes.length,
                itemBuilder: (context, index) {
                  final scheme = schemes[index];
                  final product = products.firstWhere(
                        (p) => p.id == scheme.productId,
                    orElse: () => Product(
                      id: '',
                      name: 'Unknown Product',
                      brand: '',
                      brandId: '',
                      price: 0.0,
                      stockQuantity: 0,
                      isFrozen: false,
                      inStock: false,
                    ),
                  );

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(scheme.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scheme.description),
                          Text(
                              'Amount: PKR ${scheme.amount.toStringAsFixed(2)}'),
                          Text('Product: ${product.name}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    AddEditSchemeScreen(scheme: scheme),
                              ));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDelete(context, schemeService, scheme),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SchemeService service, Scheme scheme) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${scheme.name}"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                service.deleteScheme(scheme.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scheme deleted')));
              },
            ),
          ],
        );
      },
    );
  }
}