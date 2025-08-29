// lib/UI/screens/mt_management/add_mt_claim_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:cigarette_agency_management_app/services/company_claim_service.dart';
import 'package:cigarette_agency_management_app/services/mt_service.dart';

class AddMTClaimScreen extends StatefulWidget {
  const AddMTClaimScreen({super.key});

  @override
  State<AddMTClaimScreen> createState() => _AddMTClaimScreenState();
}

class _AddMTClaimScreenState extends State<AddMTClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedMtName;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveMTClaim() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final companyClaimService = Provider.of<CompanyClaimService>(context, listen: false);

      final newClaim = CompanyClaim(
        id: '',
        type: 'MT Scheme',
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        status: 'Pending',
        dateIncurred: DateTime.now(),
        brandName: _selectedMtName,
        companyName: 'Self', // Assuming the claim is from the agency itself
      );

      try {
        await companyClaimService.addCompanyClaim(newClaim);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MT Claim added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add MT claim: $e')),
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
        title: const Text('Add MT Claim'),
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
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Please enter a valid amount.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMTClaim,
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('Save MT Claim'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
