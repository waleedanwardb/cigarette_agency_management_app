// lib/UI/screens/scheme_management/add_edit_scheme_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/services/scheme_service.dart';
import 'package:cigarette_agency_management_app/services/product_service.dart';

class AddEditSchemeScreen extends StatefulWidget {
  final Scheme? scheme;

  const AddEditSchemeScreen({super.key, this.scheme});

  @override
  State<AddEditSchemeScreen> createState() => _AddEditSchemeScreenState();
}

class _AddEditSchemeScreenState extends State<AddEditSchemeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // Changed to a list to support multi-select
  final List<Product> _selectedProducts = [];

  bool get _isEditing => widget.scheme != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.scheme!.name;
      _descriptionController.text = widget.scheme!.description;
      _amountController.text = widget.scheme!.amount.toString();
      _loadInitialProduct();
    }
  }

  // Load the single product when in editing mode
  Future<void> _loadInitialProduct() async {
    if (widget.scheme?.productId == null) return;
    final productService = Provider.of<ProductService>(context, listen: false);
    final allProducts = await productService.getProducts().first;
    try {
      final initialProduct = allProducts.firstWhere((p) => p.id == widget.scheme!.productId);
      if (!mounted) return;
      setState(() {
        _selectedProducts.add(initialProduct);
      });
    } catch (e) {
      debugPrint("Error loading initial product for scheme: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveScheme() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProducts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one product.')),
        );
        return;
      }

      final schemeService = Provider.of<SchemeService>(context, listen: false);

      try {
        if (_isEditing) {
          // When editing, update the single scheme instance
          final updatedScheme = Scheme(
            id: widget.scheme!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            amount: double.parse(_amountController.text),
            productId: _selectedProducts.first.id, // Update with the first (and only) selected product
          );
          await schemeService.updateScheme(updatedScheme);
        } else {
          // When creating, loop through selected products and create a scheme for each
          for (var product in _selectedProducts) {
            final newScheme = Scheme(
              id: '', // Firestore generates the ID
              name: _nameController.text,
              description: _descriptionController.text,
              amount: double.parse(_amountController.text),
              productId: product.id,
            );
            await schemeService.addScheme(newScheme);
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scheme(s) saved successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        debugPrint('Error saving scheme: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save scheme(s): $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Scheme' : 'Add New Scheme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Scheme Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a description' : null,
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: 'Amount (per pack)'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Applicable Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              StreamBuilder<List<Product>>(
                stream: productService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No products available to link schemes to.'),
                    );
                  }

                  final allProducts = snapshot.data!;

                  // In edit mode, disable the checklist and only show the selected product
                  if (_isEditing) {
                    return ListTile(
                      title: Text(_selectedProducts.isNotEmpty
                          ? '${_selectedProducts.first.name} (${_selectedProducts.first.brand})'
                          : 'Loading product...'),
                      subtitle: const Text('Product cannot be changed when editing a scheme.'),
                    );
                  }

                  // In add mode, show the multi-select checklist
                  return SizedBox(
                    height: 200, // Constrain the height of the list
                    child: ListView.builder(
                      itemCount: allProducts.length,
                      itemBuilder: (context, index) {
                        final product = allProducts[index];
                        final isSelected = _selectedProducts.any((p) => p.id == product.id);
                        return CheckboxListTile(
                          title: Text('${product.name} (${product.brand})'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!isSelected) {
                                  _selectedProducts.add(product);
                                }
                              } else {
                                _selectedProducts.removeWhere((p) => p.id == product.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveScheme,
                child: Text(_isEditing ? 'Save Changes' : 'Save Scheme(s)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}