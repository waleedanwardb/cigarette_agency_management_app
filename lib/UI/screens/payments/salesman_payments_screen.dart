// lib/UI/screens/payments/salesman_payments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';
import 'package:cigarette_agency_management_app/services/payment_service.dart';
import 'package:cigarette_agency_management_app/models/payment.dart';

class SalesmanPaymentsScreen extends StatefulWidget {
  const SalesmanPaymentsScreen({super.key});

  @override
  State<SalesmanPaymentsScreen> createState() => _SalesmanPaymentsScreenState();
}

class _SalesmanPaymentsScreenState extends State<SalesmanPaymentsScreen> {
  Salesman? _selectedSalesman;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  void _recordPayment() async {
    if (_selectedSalesman == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a salesman and enter an amount.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);

    final newPayment = Payment(
      id: '',
      type: 'Salesman Payment',
      referenceId: _selectedSalesman!.id,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : 'Cash payment to salesman ${_selectedSalesman!.name}',
      amount: double.tryParse(_amountController.text) ?? 0.0,
      date: Timestamp.now(),
    );

    final salesmanTransaction = SalesmanAccountTransaction(
      id: '',
      salesmanId: _selectedSalesman!.id,
      description: 'Cash given to salesman',
      date: Timestamp.now(),
      type: 'Cash Given',
      cashReceived: -newPayment.amount, // Record as a debit to the salesman's account
    );

    try {
      await paymentService.addPayment(newPayment);
      await salesmanService.recordSalesmanTransaction(
        salesmanId: _selectedSalesman!.id,
        transaction: salesmanTransaction,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of PKR ${newPayment.amount} recorded for ${_selectedSalesman!.name}.')),
      );
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedSalesman = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record payment: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesmanService = Provider.of<SalesmanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments to Salesmen'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Salesman Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            StreamBuilder<List<Salesman>>(
              stream: salesmanService.getSalesmen(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No salesmen found.');
                }
                final salesmen = snapshot.data!;
                return DropdownButtonFormField<Salesman>(
                  decoration: const InputDecoration(
                    labelText: 'Select Salesman',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSalesman,
                  items: salesmen.map((salesman) {
                    return DropdownMenuItem<Salesman>(
                      value: salesman,
                      child: Text(salesman.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSalesman = newValue;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (PKR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _recordPayment,
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
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
    );
  }
}