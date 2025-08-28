// lib/UI/screens/salesman/mt_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:cigarette_agency_management_app/services/company_claim_service.dart';
import 'package:cigarette_agency_management_app/services/mt_service.dart';

class MTScreen extends StatefulWidget {
  final Salesman salesman;

  const MTScreen({super.key, required this.salesman});

  @override
  State<MTScreen> createState() => _MTScreenState();
}

class _MTScreenState extends State<MTScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedMtName;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveMTClaim() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final companyClaimService = Provider.of<CompanyClaimService>(context, listen: false);

      final newClaim = CompanyClaim(
        id: '',
        type: 'MT Scheme',
        description: _descriptionController.text,
        amount: double.parse(_priceController.text),
        status: 'Pending',
        dateIncurred: DateTime.now(),
        brandName: _selectedMtName,
        productName: null,
        schemeNames: [_selectedMtName!],
        packsAffected: 0,
        companyName: widget.salesman.name,
      );

      try {
        await companyClaimService.addCompanyClaim(newClaim);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MT Claim recorded successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('Error recording MT claim: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to record MT claim: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mtService = Provider.of<MTService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Record MT Claim for ${widget.salesman.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<String>>(
                stream: mtService.getMTNames(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final mtNames = snapshot.data ?? [];
                  if (mtNames.isEmpty) {
                    return const Text('No MT schemes available. Please add one first.');
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select MT Scheme',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMtName,
                    items: mtNames.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMtName = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a scheme' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (PKR)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Please enter a valid price.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveMTClaim,
                  icon: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: const Text('Save MT Claim'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
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