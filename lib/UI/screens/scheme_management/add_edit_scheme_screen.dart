// lib/UI/screens/scheme_management/add_edit_scheme_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/services/scheme_service.dart';

class AddEditSchemeScreen extends StatefulWidget {
  final Scheme? scheme;

  const AddEditSchemeScreen({super.key, this.scheme});

  @override
  State<AddEditSchemeScreen> createState() => _AddEditSchemeScreenState();
}

class _AddEditSchemeScreenState extends State<AddEditSchemeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _productNameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  DateTime _validFrom = DateTime.now();
  DateTime _validTo = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scheme?.name ?? '');
    _companyController = TextEditingController(text: widget.scheme?.companyName ?? '');
    _productNameController = TextEditingController(text: widget.scheme?.productName ?? '');
    _amountController = TextEditingController(text: widget.scheme?.amount.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.scheme?.description ?? '');
    _validFrom = widget.scheme?.validFrom ?? DateTime.now();
    _validTo = widget.scheme?.validTo ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _productNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _validFrom : _validTo,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _validFrom = pickedDate;
        } else {
          _validTo = pickedDate;
        }
      });
    }
  }

  Future<void> _saveScheme() async {
    if (_formKey.currentState!.validate()) {
      final schemeService = Provider.of<SchemeService>(context, listen: false);

      final newScheme = Scheme(
        id: widget.scheme?.id ?? '',
        name: _nameController.text.trim(),
        type: 'FixedAmountPerPack', // Assuming this is the only type for now
        amount: double.parse(_amountController.text.trim()),
        isActive: widget.scheme?.isActive ?? true,
        validFrom: _validFrom,
        validTo: _validTo,
        companyName: _companyController.text.trim(),
        productName: _productNameController.text.trim(),
        description: _descriptionController.text.trim(),
        applicableProducts: 'All Cigarette Packs',
      );

      if (widget.scheme == null) {
        await schemeService.addScheme(newScheme);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheme added successfully!')));
      } else {
        await schemeService.updateScheme(newScheme);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheme updated successfully!')));
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheme == null ? 'Add New Scheme' : 'Edit Scheme'),
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
                decoration: const InputDecoration(labelText: 'Scheme Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter a company name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter a product name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount per Pack (PKR)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value!) == null ? 'Please enter a valid amount' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_validFrom)),
                      decoration: const InputDecoration(
                        labelText: 'Valid From',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_validTo)),
                      decoration: const InputDecoration(
                        labelText: 'Valid To',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveScheme,
                  child: Text(widget.scheme == null ? 'Add Scheme' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}