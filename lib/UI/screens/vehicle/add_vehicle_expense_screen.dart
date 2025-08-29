// lib/UI/screens/vehicle/add_vehicle_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:cigarette_agency_management_app/services/company_claim_service.dart';

class AddVehicleExpenseScreen extends StatefulWidget {
  const AddVehicleExpenseScreen({super.key});

  @override
  State<AddVehicleExpenseScreen> createState() => _AddVehicleExpenseScreenState();
}

class _AddVehicleExpenseScreenState extends State<AddVehicleExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedExpenseType;
  bool _isLoading = false;

  final List<String> _expenseTypes = ['Maintenance', 'Fuel', 'Other'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicleExpense() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final companyClaimService = Provider.of<CompanyClaimService>(context, listen: false);

      final newClaim = CompanyClaim(
        id: '',
        type: 'Vehicle Expense - $_selectedExpenseType',
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        status: 'Pending',
        dateIncurred: DateTime.now(),
        brandName: null,
        companyName: 'Self',
      );

      try {
        await companyClaimService.addCompanyClaim(newClaim);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle expense added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add vehicle expense: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Expense Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedExpenseType,
                items: _expenseTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExpenseType = value;
                  });
                },
                validator: (value) => value == null ? 'Please select an expense type' : null,
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
                  onPressed: _isLoading ? null : _saveVehicleExpense,
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
