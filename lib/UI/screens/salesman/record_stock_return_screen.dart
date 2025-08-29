// lib/UI/screens/salesman/record_stock_return_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import models and services
import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:cigarette_agency_management_app/models/arrear.dart';
import 'package:cigarette_agency_management_app/services/product_service.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';
import 'package:cigarette_agency_management_app/services/scheme_service.dart';
import 'package:cigarette_agency_management_app/services/company_claim_service.dart';

class RecordStockReturnScreen extends StatefulWidget {
  final Salesman salesman;
  final SalesmanAccountTransaction? transaction;

  const RecordStockReturnScreen({super.key, required this.salesman, this.transaction});

  @override
  State<RecordStockReturnScreen> createState() => _RecordStockReturnScreenState();
}

class _RecordStockReturnScreenState extends State<RecordStockReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Product> _allProducts = [];
  List<Scheme> _allActiveSchemes = [];
  Map<String, TextEditingController> _quantityControllers = {};
  Map<String, double> _grossPrices = {};
  Map<String, double> _schemeDiscounts = {};
  Map<String, double> _finalPrices = {};
  Map<String, List<Scheme>> _appliedSchemes = {};
  final _cashReceivedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    if (widget.transaction != null) {
      _selectedDate = widget.transaction!.date.toDate();
      _cashReceivedController.text = widget.transaction?.cashReceived?.toString() ?? '0';
    }
  }

  @override
  void dispose() {
    _quantityControllers.values.forEach((controller) => controller.dispose());
    _cashReceivedController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    final schemeService = Provider.of<SchemeService>(context, listen: false);

    _allProducts = await productService.getProducts().first;
    _allActiveSchemes = await schemeService.getSchemes().first;

    for (var product in _allProducts) {
      final quantity = (widget.transaction?.productName == product.name)
          ? widget.transaction?.stockReturnQuantity?.toString() ?? '0'
          : '0';
      _quantityControllers[product.id] = TextEditingController(text: quantity);
      _grossPrices[product.id] = 0.0;
      _schemeDiscounts[product.id] = 0.0;
      _finalPrices[product.id] = 0.0;
      _appliedSchemes[product.id] = [];
    }
    if (mounted) {
      _updateCalculations();
      setState(() {});
    }
  }

  void _updateCalculations() {
    if (!mounted) return;
    for (var product in _allProducts) {
      double quantity = double.tryParse(_quantityControllers[product.id]!.text) ?? 0.0;
      double pricePerUnit = product.price;
      _grossPrices[product.id] = quantity * pricePerUnit;

      _appliedSchemes[product.id] = _allActiveSchemes
          .where((s) => s.productId == product.id)
          .toList();
      _schemeDiscounts[product.id] = 0.0;
      for (var scheme in _appliedSchemes[product.id]!) {
        _schemeDiscounts[product.id] = _schemeDiscounts[product.id]! + (scheme.amount * quantity);
      }

      _finalPrices[product.id] = _grossPrices[product.id]! - _schemeDiscounts[product.id]!;
      if (_finalPrices[product.id]! < 0) _finalPrices[product.id] = 0;
    }
    setState(() {});
  }

  Future<void> _saveTransactions() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() => _isLoading = true);

      final salesmanService = Provider.of<SalesmanService>(context, listen: false);
      final companyClaimService = Provider.of<CompanyClaimService>(context, listen: false);

      try {
        double totalClaimAmount = 0.0;
        double totalExpectedPrice = 0.0;
        for (var product in _allProducts) {
          final quantity = double.tryParse(_quantityControllers[product.id]!.text) ?? 0.0;
          final cashReceived = double.tryParse(_cashReceivedController.text) ?? 0.0;

          if (quantity > 0) {
            final newTransaction = SalesmanAccountTransaction(
              id: widget.transaction?.id ?? '',
              salesmanId: widget.salesman.id,
              description: 'Stock return of ${product.name}',
              date: Timestamp.fromDate(_selectedDate),
              type: 'Stock Return',
              productName: product.name,
              brandName: product.brand,
              stockReturnQuantity: quantity,
              totalSchemeDiscount: _schemeDiscounts[product.id],
              calculatedPrice: -_finalPrices[product.id]!,
              grossPrice: -_grossPrices[product.id]!,
              appliedSchemeNames: _appliedSchemes[product.id]?.map((s) => s.name).toList(),
              cashReceived: cashReceived,
            );

            if (widget.transaction == null) {
              await salesmanService.recordSalesmanTransaction(salesmanId: widget.salesman.id, transaction: newTransaction);
            } else {
              await salesmanService.updateSalesmanTransaction(widget.salesman.id, newTransaction);
            }

            // Accumulate total claim amount for the day's transactions
            totalClaimAmount += (_schemeDiscounts[product.id] ?? 0);
            totalExpectedPrice += (_finalPrices[product.id] ?? 0);
          }
        }

        final cashReceived = double.tryParse(_cashReceivedController.text) ?? 0.0;
        final balanceDue = totalExpectedPrice - cashReceived;

        // Check for total claim amount and create a single claim for the day
        if (totalClaimAmount > 0) {
          final newClaim = CompanyClaim(
            id: '',
            type: 'Scheme Amount (Return)',
            description: 'Consolidated claim for returns on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
            amount: -totalClaimAmount,
            status: 'Pending',
            dateIncurred: _selectedDate,
            brandName: null,
            productName: null,
            schemeNames: null,
            packsAffected: null,
            companyName: widget.salesman.name,
          );
          await companyClaimService.addCompanyClaim(newClaim);
        }

        if (balanceDue > 0) {
          final newArrear = Arrear(
            id: '',
            salesmanId: widget.salesman.id,
            salesmanName: widget.salesman.name,
            amount: balanceDue,
            dateIncurred: _selectedDate,
            description: 'Arrear from stock return on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
          );
          await salesmanService.addArrear(newArrear);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock Return recorded successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('Error recording stock return: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to record stock return: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Record Stock Return for ${widget.salesman.name}' : 'Edit Stock Return for ${widget.salesman.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTransactions,
          ),
        ],
      ),
      body: _allProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDatePicker(),
              const SizedBox(height: 20),
              ..._allProducts.map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    controller: _quantityControllers[product.id],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${product.name} (${product.brand}) Return Packs',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => _updateCalculations(),
                  ),
                );
              }).toList(),
              const SizedBox(height: 15),
              TextFormField(
                controller: _cashReceivedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cash Received (PKR)',
                    border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Please enter a valid amount.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _saveTransactions,
        child: _isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Icon(Icons.save),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        const Text('Date:'),
        TextButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null && mounted) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
        ),
      ],
    );
  }
}
