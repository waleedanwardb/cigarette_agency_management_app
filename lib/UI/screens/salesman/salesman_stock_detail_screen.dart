// lib/UI/screens/salesman/salesman_stock_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Import models and services
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';
import 'package:cigarette_agency_management_app/services/product_service.dart';
import 'package:cigarette_agency_management_app/services/scheme_service.dart';
import 'package:cigarette_agency_management_app/services/company_claim_service.dart';

// Import main screens for BottomNavigationBar navigation
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';

class SalesmanStockDetailScreen extends StatefulWidget {
  final Salesman salesman;

  const SalesmanStockDetailScreen({super.key, required this.salesman});

  @override
  State<SalesmanStockDetailScreen> createState() =>
      _SalesmanStockDetailScreenState();
}

class _SalesmanStockDetailScreenState extends State<SalesmanStockDetailScreen> {
  int _selectedIndex = 2; // Assuming Stock is the 3rd item (index 2) in bottom nav

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => [
              const HomeScreen(),
              const DashboardScreen(),
              const StockMainScreen(),
              const PaymentsMainScreen()
            ][index]),
      );
    }
  }

  Future<void> _showStockOutDialog({SalesmanAccountTransaction? transaction}) async {
    final _formKey = GlobalKey<FormState>();
    DateTime selectedDate = transaction?.date.toDate() ?? DateTime.now();
    final productService = Provider.of<ProductService>(context, listen: false);
    final salesmanService =
    Provider.of<SalesmanService>(context, listen: false);
    final companyClaimService =
    Provider.of<CompanyClaimService>(context, listen: false);
    final schemeService = Provider.of<SchemeService>(context, listen: false);

    bool _isLoading = false;
    List<Product> _allProducts = [];
    List<Scheme> _allActiveSchemes = [];
    Map<String, TextEditingController> _quantityControllers = {};
    Map<String, double> _grossPrices = {};
    Map<String, double> _schemeDiscounts = {};
    Map<String, double> _finalPrices = {};
    Map<String, List<Scheme>> _appliedSchemes = {};

    _allProducts = await productService.getProducts().first;
    _allActiveSchemes = await schemeService.getSchemes().first;

    for (var product in _allProducts) {
      _quantityControllers[product.id] = TextEditingController(text: transaction?.stockOutQuantity?.toString() ?? '');
      _grossPrices[product.id] = 0.0;
      _schemeDiscounts[product.id] = 0.0;
      _finalPrices[product.id] = 0.0;
      _appliedSchemes[product.id] = [];
    }
    if (transaction != null) {
      // Pre-fill quantities if editing
      final product = _allProducts.firstWhere((p) => p.name == transaction.productName);
      _quantityControllers[product.id]?.text = transaction.stockOutQuantity.toString();
    }


    void updateCalculations(Function setStateInDialog) {
      if (!mounted) return;
      for (var product in _allProducts) {
        double quantity =
            double.tryParse(_quantityControllers[product.id]!.text) ?? 0.0;
        double pricePerUnit = product.price;
        _grossPrices[product.id] = quantity * pricePerUnit;

        _appliedSchemes[product.id] = _allActiveSchemes
            .where((s) => s.productId == product.id)
            .toList();
        _schemeDiscounts[product.id] = 0.0;
        for (var scheme in _appliedSchemes[product.id]!) {
          _schemeDiscounts[product.id] =
              _schemeDiscounts[product.id]! + (scheme.amount * quantity);
        }

        _finalPrices[product.id] =
            _grossPrices[product.id]! - _schemeDiscounts[product.id]!;
        if (_finalPrices[product.id]! < 0) _finalPrices[product.id] = 0;
      }
      setStateInDialog(() {});
    }

    await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(transaction == null ? 'Record Stock Out' : 'Edit Stock Out'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._allProducts.map((product) {
                        final schemesForProduct = _allActiveSchemes
                            .where((s) => s.productId == product.id)
                            .toList();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _quantityControllers[product.id],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText:
                                    '${product.name} (${product.brand}) Packs',
                                    hintText: 'Price/Pack: PKR ${product.price.toStringAsFixed(2)}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) =>
                                      updateCalculations(setStateInDialog),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    'Cost of Packs: PKR ${_grossPrices[product.id]!.toStringAsFixed(2)}'),
                                if (schemesForProduct.isNotEmpty)
                                  ...schemesForProduct.map((scheme) {
                                    return Text(
                                        '${scheme.name} Discount: -PKR ${scheme.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.deepOrange));
                                  }).toList(),
                                Text(
                                    'Total Scheme Discount: PKR ${_schemeDiscounts[product.id]!.toStringAsFixed(2)}'),
                                Text(
                                  'Final Amount: PKR ${_finalPrices[product.id]!.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      if (!mounted) return;
                      setStateInDialog(() {
                        _isLoading = true;
                      });
                      try {
                        for (var product in _allProducts) {
                          final quantity = double.tryParse(
                              _quantityControllers[product.id]!
                                  .text) ??
                              0.0;
                          if (quantity > 0) {
                            final newTransaction =
                            SalesmanAccountTransaction(
                              id: transaction?.id ?? '',
                              salesmanId: widget.salesman.id,
                              description:
                              'Stock out of ${product.name}',
                              date: Timestamp.fromDate(selectedDate),
                              type: 'Stock Out',
                              productName: product.name,
                              brandName: product.brand,
                              stockOutQuantity: quantity,
                              totalSchemeDiscount:
                              _schemeDiscounts[product.id],
                              calculatedPrice: _finalPrices[product.id],
                              grossPrice: _grossPrices[product.id],
                              appliedSchemeNames:
                              _appliedSchemes[product.id]
                                  ?.map((s) => s.name)
                                  .toList(),
                            );

                            if (transaction == null) {
                              await salesmanService
                                  .recordSalesmanTransaction(
                                salesmanId: widget.salesman.id,
                                transaction: newTransaction,
                              );
                            } else {
                              await salesmanService.updateSalesmanTransaction(widget.salesman.id, newTransaction);
                            }


                            if (_schemeDiscounts[product.id]! > 0) {
                              final newClaim = CompanyClaim(
                                id: '',
                                type: 'Scheme Amount',
                                description:
                                'Claim for scheme discount on ${product.name}',
                                amount: _schemeDiscounts[product.id]!,
                                status: 'Pending',
                                dateIncurred: selectedDate,
                                brandName: product.brand,
                                productName: product.name,
                                schemeNames:
                                _appliedSchemes[product.id]!
                                    .map((s) => s.name)
                                    .toList(),
                                packsAffected: quantity,
                                companyName: product.brand,
                              );
                              await companyClaimService
                                  .addCompanyClaim(newClaim);
                            }
                          }
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Stock Out transaction ${transaction == null ? 'recorded' : 'updated'} successfully!')),
                        );
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        debugPrint('Error recording stock out: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Failed to record transaction: $e')),
                        );
                      } finally {
                        if (!mounted) return;
                        setStateInDialog(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: Text(transaction == null ? 'Confirm Stock Out' : 'Update'),
                ),
              ],
            );
          });
        });
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
  }

  Future<void> _showStockReturnDialog({SalesmanAccountTransaction? transaction}) async {
    final _formKey = GlobalKey<FormState>();
    DateTime selectedDate = transaction?.date.toDate() ?? DateTime.now();

    final productService = Provider.of<ProductService>(context, listen: false);
    final salesmanService =
    Provider.of<SalesmanService>(context, listen: false);
    final companyClaimService =
    Provider.of<CompanyClaimService>(context, listen: false);
    final schemeService = Provider.of<SchemeService>(context, listen: false);

    bool _isLoading = false;
    List<Product> _allProducts = [];
    List<Scheme> _allActiveSchemes = [];
    Map<String, TextEditingController> _quantityControllers = {};
    Map<String, double> _grossPrices = {};
    Map<String, double> _schemeDiscounts = {};
    Map<String, double> _finalPrices = {};
    Map<String, List<Scheme>> _appliedSchemes = {};

    _allProducts = await productService.getProducts().first;
    _allActiveSchemes = await schemeService.getSchemes().first;

    for (var product in _allProducts) {
      _quantityControllers[product.id] = TextEditingController(text: transaction?.stockReturnQuantity?.toString() ?? '');
      _grossPrices[product.id] = 0.0;
      _schemeDiscounts[product.id] = 0.0;
      _finalPrices[product.id] = 0.0;
      _appliedSchemes[product.id] = [];
    }
    if (transaction != null) {
      // Pre-fill quantities if editing
      final product = _allProducts.firstWhere((p) => p.name == transaction.productName);
      _quantityControllers[product.id]?.text = transaction.stockReturnQuantity.toString();
    }

    void updateCalculations(Function setStateInDialog) {
      if (!mounted) return;
      double totalGross = 0;
      double totalDiscount = 0;
      double totalFinal = 0;

      for (var product in _allProducts) {
        double quantity =
            double.tryParse(_quantityControllers[product.id]!.text) ?? 0.0;
        double pricePerUnit = product.price;
        _grossPrices[product.id] = quantity * pricePerUnit;

        _appliedSchemes[product.id] = _allActiveSchemes
            .where((s) => s.productId == product.id)
            .toList();
        _schemeDiscounts[product.id] = 0.0;
        for (var scheme in _appliedSchemes[product.id]!) {
          _schemeDiscounts[product.id] =
              _schemeDiscounts[product.id]! + (scheme.amount * quantity);
        }

        _finalPrices[product.id] =
            _grossPrices[product.id]! - _schemeDiscounts[product.id]!;
        if (_finalPrices[product.id]! < 0) _finalPrices[product.id] = 0;

        totalGross += _grossPrices[product.id]!;
        totalDiscount += _schemeDiscounts[product.id]!;
        totalFinal += _finalPrices[product.id]!;
      }
      setStateInDialog(() {});
    }

    await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(builder: (context, setStateInDialog) {
            return AlertDialog(
                title: Text(transaction == null ?'Record Stock Return' : 'Edit Stock Return'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._allProducts.map((product) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextFormField(
                              controller: _quantityControllers[product.id],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText:
                                '${product.name} (${product.brand}) Return Packs',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) =>
                                  updateCalculations(setStateInDialog),
                            ),
                          );
                        }).toList(),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                  ),
                  ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                        if (_formKey.currentState!.validate()) {
                          setStateInDialog(() {
                            _isLoading = true;
                          });
                          try {
                            for (var product in _allProducts) {
                              final quantity = double.tryParse(
                                  _quantityControllers[product.id]!
                                      .text) ??
                                  0.0;
                              if (quantity > 0) {
                                final newTransaction =
                                SalesmanAccountTransaction(
                                  id: transaction?.id ?? '',
                                  salesmanId: widget.salesman.id,
                                  description:
                                  'Stock return of ${product.name}',
                                  date: Timestamp.fromDate(selectedDate),
                                  type: 'Stock Return',
                                  productName: product.name,
                                  brandName: product.brand,
                                  stockReturnQuantity: quantity,
                                  totalSchemeDiscount:
                                  _schemeDiscounts[product.id],
                                  calculatedPrice:
                                  -_finalPrices[product.id]!,
                                  grossPrice: -_grossPrices[product.id]!,
                                  appliedSchemeNames:
                                  _appliedSchemes[product.id]
                                      ?.map((s) => s.name)
                                      .toList(),
                                );
                                if (transaction == null) {
                                  await salesmanService
                                      .recordSalesmanTransaction(
                                    salesmanId: widget.salesman.id,
                                    transaction: newTransaction,
                                  );
                                } else {
                                  await salesmanService.updateSalesmanTransaction(widget.salesman.id, newTransaction);
                                }


                                if (_schemeDiscounts[product.id]! > 0) {
                                  final newClaim = CompanyClaim(
                                    id: '',
                                    type: 'Scheme Amount (Return)',
                                    description:
                                    'Claim adjustment for returned scheme on ${product.name}',
                                    amount:
                                    -_schemeDiscounts[product.id]!,
                                    status: 'Pending',
                                    dateIncurred: selectedDate,
                                    brandName: product.brand,
                                    productName: product.name,
                                    schemeNames: _appliedSchemes[
                                    product.id]!
                                        .map((s) => s.name)
                                        .toList(),
                                    packsAffected: quantity,
                                    companyName: product.brand,
                                  );
                                  await companyClaimService
                                      .addCompanyClaim(newClaim);
                                }
                              }
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Stock Return transaction ${transaction == null ? 'recorded' : 'updated'} successfully!')),
                            );
                            Navigator.of(dialogContext).pop();
                          } catch (e) {
                            debugPrint(
                                'Error recording stock return: $e');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to record transaction: $e')),
                            );
                          } finally {
                            if (!mounted) return;
                            setStateInDialog(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      child: Text(transaction == null ? 'Confirm Return': 'Update'))
                ]);
          });
        });
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
  }

  Future<void> _showCashReceivedDialog({SalesmanAccountTransaction? transaction}) async {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController(text: transaction?.cashReceived?.toString() ?? '');
    DateTime selectedDate = transaction?.date.toDate() ?? DateTime.now();
    final salesmanService =
    Provider.of<SalesmanService>(context, listen: false);
    bool _isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(transaction == null ? 'Record Cash Received' : 'Edit Cash Received'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount (PKR)',
                          border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null ||
                            double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter a valid amount.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(selectedDate)),
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          if (!mounted) return;
                          setStateInDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed:
                  _isLoading ? null : () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: _isLoading ||
                      _formKey.currentState == null ||
                      !_formKey.currentState!.validate()
                      ? null
                      : () async {
                    if (!mounted) return;
                    setStateInDialog(() {
                      _isLoading = true;
                    });

                    final newTransaction = SalesmanAccountTransaction(
                      id: transaction?.id ?? '',
                      salesmanId: widget.salesman.id,
                      description: 'Cash payment from salesman.',
                      date: Timestamp.fromDate(selectedDate),
                      type: 'Cash Received',
                      cashReceived:
                      double.parse(_amountController.text),
                    );

                    try {
                      if (transaction == null) {
                        await salesmanService.recordSalesmanTransaction(
                          salesmanId: widget.salesman.id,
                          transaction: newTransaction,
                        );
                      } else {
                        await salesmanService.updateSalesmanTransaction(widget.salesman.id, newTransaction);
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Cash received transaction ${transaction == null ? 'recorded' : 'updated'} successfully!')),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      debugPrint('Error recording cash received: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to record transaction: $e')),
                      );
                    } finally {
                      if (!mounted) return;
                      setStateInDialog(() {
                        _isLoading = false;
                      });
                    }
                  },
                  child: Text(transaction == null ? 'Confirm' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
    _amountController.dispose();
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating report... (Feature coming soon)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesmanService = Provider.of<SalesmanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.salesman.name}\'s Stock',
          style: const TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile
            },
          ),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<SalesmanAccountTransaction>>(
          stream: salesmanService.getSalesmanTransactions(widget.salesman.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allTransactions = snapshot.data ?? [];
            List<SalesmanAccountTransaction> filteredTransactions =
            allTransactions.where((transaction) {
              final transactionDate = transaction.date.toDate();
              bool matchesStartDate = _filterStartDate == null ||
                  transactionDate.isAtSameMomentAs(_filterStartDate!) ||
                  transactionDate.isAfter(_filterStartDate!);
              bool matchesEndDate = _filterEndDate == null ||
                  transactionDate.isAtSameMomentAs(_filterEndDate!) ||
                  transactionDate.isBefore(_filterEndDate!);
              return matchesStartDate && matchesEndDate;
            }).toList();

            double stockOutValue = filteredTransactions
                .where((t) => t.type == 'Stock Out')
                .fold(0.0, (sum, t) => sum + (t.calculatedPrice ?? 0));
            double stockReturnValue = filteredTransactions
                .where((t) => t.type == 'Stock Return')
                .fold(0.0, (sum, t) => sum + (t.calculatedPrice ?? 0));
            double totalCashReceived = filteredTransactions
                .where((t) => t.type == 'Cash Received')
                .fold(0.0, (sum, t) => sum + (t.cashReceived ?? 0));
            double totalStockAssigned = filteredTransactions
                .where((t) => t.type == 'Stock Out')
                .fold(0.0, (sum, t) => sum + (t.stockOutQuantity ?? 0));
            double totalStockReturned = filteredTransactions
                .where((t) => t.type == 'Stock Return')
                .fold(0.0, (sum, t) => sum + (t.stockReturnQuantity ?? 0));

            double totalTransactionValue = stockOutValue - stockReturnValue;
            double balanceDue = totalTransactionValue - totalCashReceived;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      String title;
                      String value;
                      IconData icon;
                      Color color;

                      switch (index) {
                        case 0:
                          title = 'Stock Assigned';
                          value = (totalStockAssigned - totalStockReturned)
                              .toStringAsFixed(0) +
                              ' Packs';
                          icon = Icons.assignment_turned_in;
                          color = Colors.blue;
                          break;
                        case 1:
                          title = 'Stock Value';
                          value =
                          'PKR ${totalTransactionValue.toStringAsFixed(2)}';
                          icon = Icons.shopping_cart;
                          color = Colors.green;
                          break;
                        case 2:
                          title = 'Amount Received';
                          value =
                          'PKR ${totalCashReceived.toStringAsFixed(2)}';
                          icon = Icons.payments;
                          color = Colors.orange;
                          break;
                        case 3:
                          title = 'Balance Due';
                          value = 'PKR ${balanceDue.toStringAsFixed(2)}';
                          icon = Icons.account_balance_wallet;
                          color = Colors.red;
                          break;
                        default:
                          title = '';
                          value = '';
                          icon = Icons.help;
                          color = Colors.grey;
                      }

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(icon, color: color, size: 28),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700]),
                                  ),
                                  Text(
                                    value,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Record Actions',
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showStockOutDialog,
                          icon: const Icon(Icons.outbox),
                          label: const Text('Record Stock Out'),
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showStockReturnDialog,
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Record Stock Return'),
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showCashReceivedDialog,
                          icon: const Icon(Icons.attach_money),
                          label: const Text('Record Cash Received'),
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Filter Transactions',
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _filterStartDate == null
                                  ? ''
                                  : DateFormat('yyyy-MM-dd')
                                  .format(_filterStartDate!)),
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate:
                              _filterStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              if (!mounted) return;
                              setState(() {
                                _filterStartDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _filterEndDate == null
                                  ? ''
                                  : DateFormat('yyyy-MM-dd')
                                  .format(_filterEndDate!)),
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _filterEndDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              if (!mounted) return;
                              setState(() {
                                _filterEndDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _filterStartDate = null;
                          _filterEndDate = null;
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Recent Transactions',
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12.0,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 60,
                      columns: const [
                        DataColumn(
                            label: Text('Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Type',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Brand',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Out (Packs)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Return (Packs)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Cash Received (PKR)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Total Amount (PKR)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Schemes',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredTransactions.map((transaction) {
                        return DataRow(
                          cells: [
                            DataCell(Text(DateFormat('yyyy-MM-dd')
                                .format(transaction.date.toDate()))),
                            DataCell(Text(transaction.type)),
                            DataCell(Text(transaction.brandName ?? '-')),
                            DataCell(Text(transaction.stockOutQuantity
                                ?.toStringAsFixed(0) ??
                                '-')),
                            DataCell(Text(transaction.stockReturnQuantity
                                ?.toStringAsFixed(0) ??
                                '-')),
                            DataCell(Text(transaction.cashReceived
                                ?.toStringAsFixed(2) ??
                                '-')),
                            DataCell(Text(transaction.calculatedPrice
                                ?.toStringAsFixed(2) ??
                                '-')),
                            DataCell(Text(transaction.appliedSchemeNames
                                ?.join(', ') ??
                                '-')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      if (transaction.type == 'Stock Out') {
                                        _showStockOutDialog(transaction: transaction);
                                      } else if (transaction.type == 'Stock Return') {
                                        _showStockReturnDialog(transaction: transaction);
                                      } else if (transaction.type == 'Cash Received') {
                                        _showCashReceivedDialog(transaction: transaction);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(context: context, builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Confirm Delete'),
                                          content: const Text('Are you sure you want to delete this transaction?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                            TextButton(
                                              child: const Text('Delete'),
                                              onPressed: () {
                                                salesmanService.deleteSalesmanTransaction(widget.salesman.id, transaction.id);
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.download),
                      label: const Text('Generate Report (Excel/PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}