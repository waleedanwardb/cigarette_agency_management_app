// lib/UI/screens/scheme_management/add_edit_scheme_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';

import '../../../models/product.dart'; // Import Product for its dummy data (if you moved Product out, adjust path)


class AddEditSchemeScreen extends StatefulWidget {
  final Scheme? scheme;

  const AddEditSchemeScreen({super.key, this.scheme});

  @override
  State<AddEditSchemeScreen> createState() => _AddEditSchemeScreenState();
}

class _AddEditSchemeScreenState extends State<AddEditSchemeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _companyController; // New controller
  late TextEditingController _descriptionController;
  late TextEditingController _applicableProductsController;

  String _selectedType = 'FixedAmountPerPack';
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validTo;
  Product? _selectedProduct; // For specific product selection

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scheme?.name ?? '');
    _amountController = TextEditingController(text: widget.scheme?.amount.toString() ?? '');
    _companyController = TextEditingController(text: widget.scheme?.companyName ?? ''); // Initialize
    _descriptionController = TextEditingController(text: widget.scheme?.description ?? '');
    _applicableProductsController = TextEditingController(text: widget.scheme?.applicableProducts ?? '');

    _selectedType = widget.scheme?.type ?? 'FixedAmountPerPack';
    _isActive = widget.scheme?.isActive ?? true;
    _validFrom = widget.scheme?.validFrom ?? DateTime.now();
    _validTo = widget.scheme?.validTo ?? DateTime.now().add(const Duration(days: 30));

    if (widget.scheme != null && Product.dummyProducts.isNotEmpty) {
      _selectedProduct = Product.dummyProducts.firstWhere(
            (p) => p.name == widget.scheme!.productName,
        orElse: () => Product.dummyProducts.first,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _applicableProductsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {required bool isStartDate}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_validFrom ?? DateTime.now()) : (_validTo ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _validFrom = picked;
          if (_validTo != null && _validFrom!.isAfter(_validTo!)) {
            _validTo = _validFrom!.add(const Duration(days: 1));
          }
        } else {
          _validTo = picked;
          if (_validFrom != null && _validTo!.isBefore(_validFrom!)) {
            _validFrom = _validTo!.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  void _saveScheme() {
    if (_formKey.currentState!.validate()) {
      final newScheme = Scheme(
        id: widget.scheme?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        isActive: _isActive,
        validFrom: _validFrom!,
        validTo: _validTo!,
        companyName: _companyController.text,
        productName: _selectedProduct?.name ?? 'Not Specified',
        description: _descriptionController.text,
        applicableProducts: _applicableProductsController.text,
      );
      Navigator.pop(context, newScheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheme == null ? 'Add New Scheme' : 'Edit Scheme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Scheme Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.loyalty),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter scheme name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField( // NEW: Company Name
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<Product>( // NEW: Product Dropdown
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                value: _selectedProduct,
                items: Product.dummyProducts.map((product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text(product.name),
                  );
                }).toList(),
                onChanged: (Product? newValue) {
                  setState(() {
                    _selectedProduct = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a product' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Scheme Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'FixedAmountPerPack', child: Text('Fixed Amount Per Pack')),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Select scheme type' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR per pack)', // Label updated
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _applicableProductsController,
                decoration: const InputDecoration(
                  labelText: 'Applicable Products (General Description)',
                  hintText: 'e.g., All Cigarette Packs, Marlboro Red',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.widgets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please specify applicable products';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              SwitchListTile(
                title: const Text('Is Active'),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                secondary: const Icon(Icons.power_settings_new),
              ),
              const SizedBox(height: 15),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _validFrom == null ? 'Select Start Date' : DateFormat('yyyy-MM-dd').format(_validFrom!)),
                decoration: const InputDecoration(
                  labelText: 'Valid From',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _pickDate(context, isStartDate: true),
                validator: (value) {
                  if (_validFrom == null) return 'Please select a start date';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _validTo == null ? 'Select End Date' : DateFormat('yyyy-MM-dd').format(_validTo!)),
                decoration: const InputDecoration(
                  labelText: 'Valid To',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _pickDate(context, isStartDate: false),
                validator: (value) {
                  if (_validTo == null) return 'Please select an end date';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveScheme,
                  icon: const Icon(Icons.save),
                  label: Text(widget.scheme == null ? 'Add Scheme' : 'Update Scheme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}