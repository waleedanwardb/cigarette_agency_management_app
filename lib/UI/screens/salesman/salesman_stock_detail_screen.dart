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
  State<SalesmanStockDetailScreen> createState() => _SalesmanStockDetailScreenState();
}

class _SalesmanStockDetailScreenState extends State<SalesmanStockDetailScreen> {
  int _selectedIndex = 2; // Assuming Stock is the 3rd item (index 2) in bottom nav

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  void _onItemTapped(int index) {
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

  Future<List<Scheme>?> _showMultiSelectSchemeDialog(
      BuildContext context, List<Scheme> currentSelectedSchemes) async {
    final schemeService = Provider.of<SchemeService>(context, listen: false);
    final allActiveSchemes = await schemeService.getSchemes().first;
    final List<Scheme> tempSelectedSchemes = List.from(currentSelectedSchemes);

    return await showDialog<List<Scheme>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Schemes to Apply'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateInDialog) {
                return ListBody(
                  children: allActiveSchemes.map((scheme) {
                    bool isSelected = tempSelectedSchemes.any((s) => s.id == scheme.id);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text('${scheme.name} (PKR ${scheme.amount.toStringAsFixed(2)}/pack)'),
                      subtitle: Text(scheme.description),
                      onChanged: (bool? checked) {
                        setStateInDialog(() {
                          if (checked != null && checked) {
                            if (!tempSelectedSchemes.any((s) => s.id == scheme.id)) {
                              tempSelectedSchemes.add(scheme);
                            }
                          } else {
                            tempSelectedSchemes.removeWhere((s) => s.id == scheme.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
            ),
            ElevatedButton(
              child: const Text('Apply'),
              onPressed: () {
                Navigator.of(dialogContext).pop(tempSelectedSchemes);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStockOutDialog() async {
    final _formKey = GlobalKey<FormState>();
    Product? selectedProduct;
    final _quantityController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final productService = Provider.of<ProductService>(context, listen: false);
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);
    final companyClaimService = Provider.of<CompanyClaimService>(context, listen: false);

    double _dialogCalculatedGrossPrice = 0.0;
    double _dialogTotalSchemeDiscount = 0.0;
    double _dialogFinalPriceAfterScheme = 0.0;
    List<Scheme> _dialogSelectedSchemes = [];
    bool _isLoading = false;

    void updateCalculations(Function setStateInDialog) {
      double quantity = double.tryParse(_quantityController.text) ?? 0.0;
      double pricePerUnit = selectedProduct?.price ?? 0.0;

      setStateInDialog(() {
        _dialogCalculatedGrossPrice = quantity * pricePerUnit;
        _dialogTotalSchemeDiscount = 0.0;
        for (var scheme in _dialogSelectedSchemes) {
          _dialogTotalSchemeDiscount += scheme.amount * quantity;
        }
        _dialogFinalPriceAfterScheme = _dialogCalculatedGrossPrice - _dialogTotalSchemeDiscount;
        if (_dialogFinalPriceAfterScheme < 0) _dialogFinalPriceAfterScheme = 0;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Record Stock Out'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<List<Product>>(
                        stream: productService.getProducts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No products available.');
                          }
                          return DropdownButtonFormField<Product>(
                            decoration: const InputDecoration(
                              labelText: 'Choose Product',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedProduct,
                            items: snapshot.data!.map((product) {
                              return DropdownMenuItem<Product>(
                                value: product,
                                child: Text('${product.name} (${product.brand})'),
                              );
                            }).toList(),
                            onChanged: (Product? newValue) {
                              setStateInDialog(() {
                                selectedProduct = newValue;
                                _dialogSelectedSchemes = [];
                                updateCalculations(setStateInDialog);
                              });
                            },
                            validator: (value) => value == null ? 'Please select a product' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount of Stock (Packs)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => updateCalculations(setStateInDialog),
                        validator: (value) {
                          if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Please enter a valid quantity.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final List<Scheme>? picked =
                            await _showMultiSelectSchemeDialog(context, _dialogSelectedSchemes);
                            if (picked != null) {
                              setStateInDialog(() {
                                _dialogSelectedSchemes = picked;
                                updateCalculations(setStateInDialog);
                              });
                            }
                          },
                          icon: const Icon(Icons.loyalty),
                          label: Text('Apply Schemes (${_dialogSelectedSchemes.length} selected)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: 'Gross: PKR ${_dialogCalculatedGrossPrice.toStringAsFixed(2)}'),
                        decoration: InputDecoration(
                          labelText: 'Gross Price',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.grey[100],
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: 'Total Scheme Discount: PKR ${_dialogTotalSchemeDiscount.toStringAsFixed(2)}'),
                        decoration: InputDecoration(
                          labelText: 'Total Scheme Discount',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.orange[50],
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: 'Final: PKR ${_dialogFinalPriceAfterScheme.toStringAsFixed(2)}'),
                        decoration: InputDecoration(
                          labelText: 'Final Price (After Scheme)',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.lightGreen[50],
                          filled: true,
                        ),
                      ),
                      if (_isLoading) const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: _isLoading ? null : () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  onPressed: _isLoading || _formKey.currentState == null || !_formKey.currentState!.validate() || selectedProduct == null
                      ? null
                      : () async {
                    setStateInDialog(() { _isLoading = true; });

                    final transaction = SalesmanAccountTransaction(
                      id: '',
                      salesmanId: widget.salesman.id,
                      description: 'Stock out of ${selectedProduct!.name}',
                      date: Timestamp.fromDate(selectedDate),
                      type: 'Stock Out',
                      productName: selectedProduct!.name,
                      brandName: selectedProduct!.brand,
                      stockOutQuantity: double.parse(_quantityController.text),
                      totalSchemeDiscount: _dialogTotalSchemeDiscount,
                      calculatedPrice: _dialogFinalPriceAfterScheme,
                      grossPrice: _dialogCalculatedGrossPrice,
                      appliedSchemeNames: _dialogSelectedSchemes.map((s) => s.name).toList(),
                    );

                    try {
                      await salesmanService.recordSalesmanTransaction(
                        salesmanId: widget.salesman.id,
                        transaction: transaction,
                      );

                      if (_dialogTotalSchemeDiscount > 0) {
                        final newClaim = CompanyClaim(
                          id: '',
                          type: 'Scheme Amount',
                          description: 'Claim for scheme discount on ${selectedProduct!.name}',
                          amount: _dialogTotalSchemeDiscount,
                          status: 'Pending',
                          dateIncurred: selectedDate,
                          brandName: selectedProduct!.brand,
                          productName: selectedProduct!.name,
                          schemeNames: _dialogSelectedSchemes.map((s) => s.name).toList(),
                          packsAffected: double.parse(_quantityController.text),
                          companyName: selectedProduct!.brand,
                        );
                        await companyClaimService.addCompanyClaim(newClaim);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock Out transaction recorded successfully!')),
                      );
                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      debugPrint('Error recording stock out: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to record transaction: $e')),
                      );
                    } finally {
                      setStateInDialog(() { _isLoading = false; });
                    }
                  },
                  child: const Text('Confirm Stock Out'),
                ),
              ],
            );
          },
        );
      },
    );
    _quantityController.dispose();
  }

  Future<void> _showStockReturnDialog() async {
    final _formKey = GlobalKey<FormState>();
    Product? selectedProduct;
    final _quantityController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final productService = Provider.of<ProductService>(context, listen: false);
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);
    final companyClaimService = Provider.of<CompanyClaimService>(context, listen: false);

    double _dialogCalculatedGrossPrice = 0.0;
    double _dialogTotalSchemeDiscount = 0.0;
    double _dialogFinalPriceAfterScheme = 0.0;
    List<Scheme> _dialogSelectedSchemes = [];
    bool _isLoading = false;

    void updateCalculations(Function setStateInDialog) {
      double quantity = double.tryParse(_quantityController.text) ?? 0.0;
      double pricePerUnit = selectedProduct?.price ?? 0.0;

      setStateInDialog(() {
        _dialogCalculatedGrossPrice = quantity * pricePerUnit;
        _dialogTotalSchemeDiscount = 0.0;
        for (var scheme in _dialogSelectedSchemes) {
          _dialogTotalSchemeDiscount += scheme.amount * quantity;
        }
        _dialogFinalPriceAfterScheme = _dialogCalculatedGrossPrice - _dialogTotalSchemeDiscount;
        if (_dialogFinalPriceAfterScheme < 0) _dialogFinalPriceAfterScheme = 0;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Record Stock Return'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<List<Product>>(
                        stream: productService.getProducts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No products available.');
                          }
                          return DropdownButtonFormField<Product>(
                            decoration: const InputDecoration(
                              labelText: 'Choose Product',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedProduct,
                            items: snapshot.data!.map((product) {
                              return DropdownMenuItem<Product>(
                                value: product,
                                child: Text('${product.name} (${product.brand})'),
                              );
                            }).toList(),
                            onChanged: (Product? newValue) {
                              setStateInDialog(() {
                                selectedProduct = newValue;
                                _dialogSelectedSchemes = [];
                                updateCalculations(setStateInDialog);
                              });
                            },
                            validator: (value) => value == null ? 'Please select a product' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Return Quantity (Packs)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => updateCalculations(setStateInDialog),
                        validator: (value) {
                          if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Please enter a valid quantity.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final List<Scheme>? picked =
                            await _showMultiSelectSchemeDialog(context, _dialogSelectedSchemes);
                            if (picked != null) {
                              setStateInDialog(() {
                                _dialogSelectedSchemes = picked;
                                updateCalculations(setStateInDialog);
                              });
                            }
                          },
                          icon: const Icon(Icons.loyalty),
                          label: Text('Applied Schemes (${_dialogSelectedSchemes.length} selected)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: 'PKR ${_dialogFinalPriceAfterScheme.toStringAsFixed(2)} Value'),
                        decoration: InputDecoration(
                          labelText: 'Calculated Return Value',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.grey[100],
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: 'Total Scheme Discount: PKR ${_dialogTotalSchemeDiscount.toStringAsFixed(2)}'),
                        decoration: InputDecoration(
                          labelText: 'Total Scheme Discount (Return)',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.orange[50],
                          filled: true,
                        ),
                      ),
                      if (_isLoading) const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: _isLoading ? null : () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  onPressed: _isLoading || _formKey.currentState == null || !_formKey.currentState!.validate() || selectedProduct == null
                      ? null
                      : () async {
                    setStateInDialog(() { _isLoading = true; });

                    final transaction = SalesmanAccountTransaction(
                      id: '',
                      salesmanId: widget.salesman.id,
                      description: 'Stock return of ${selectedProduct!.name}',
                      date: Timestamp.fromDate(selectedDate),
                      type: 'Stock Return',
                      productName: selectedProduct!.name,
                      brandName: selectedProduct!.brand,
                      stockReturnQuantity: double.parse(_quantityController.text),
                      totalSchemeDiscount: _dialogTotalSchemeDiscount,
                      calculatedPrice: -_dialogFinalPriceAfterScheme,
                      grossPrice: -_dialogCalculatedGrossPrice,
                      appliedSchemeNames: _dialogSelectedSchemes.map((s) => s.name).toList(),
                    );

                    try {
                      await salesmanService.recordSalesmanTransaction(
                        salesmanId: widget.salesman.id,
                        transaction: transaction,
                      );

                      if (_dialogTotalSchemeDiscount > 0) {
                        final newClaim = CompanyClaim(
                          id: '',
                          type: 'Scheme Amount (Return)',
                          description: 'Claim adjustment for returned scheme on ${selectedProduct!.name}',
                          amount: -_dialogTotalSchemeDiscount,
                          status: 'Pending',
                          dateIncurred: selectedDate,
                          brandName: selectedProduct!.brand,
                          productName: selectedProduct!.name,
                          schemeNames: _dialogSelectedSchemes.map((s) => s.name).toList(),
                          packsAffected: double.parse(_quantityController.text),
                          companyName: selectedProduct!.brand,
                        );
                        await companyClaimService.addCompanyClaim(newClaim);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock Return transaction recorded successfully!')),
                      );
                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      debugPrint('Error recording stock return: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to record transaction: $e')),
                      );
                    } finally {
                      setStateInDialog(() { _isLoading = false; });
                    }
                  },
                  child: const Text('Confirm Return'),
                ),
              ],
            );
          },
        );
      },
    );
    _quantityController.dispose();
  }

  Future<void> _showCashReceivedDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);
    bool _isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Record Cash Received'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount (PKR)', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
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
                          setStateInDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    if (_isLoading) const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: _isLoading || _formKey.currentState == null || !_formKey.currentState!.validate()
                      ? null
                      : () async {
                    setStateInDialog(() { _isLoading = true; });

                    final transaction = SalesmanAccountTransaction(
                      id: '',
                      salesmanId: widget.salesman.id,
                      description: 'Cash payment from salesman.',
                      date: Timestamp.fromDate(selectedDate),
                      type: 'Cash Received',
                      cashReceived: double.parse(_amountController.text),
                    );

                    try {
                      await salesmanService.recordSalesmanTransaction(
                        salesmanId: widget.salesman.id,
                        transaction: transaction,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cash received transaction recorded successfully!')),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      debugPrint('Error recording cash received: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to record transaction: $e')),
                      );
                    } finally {
                      setStateInDialog(() { _isLoading = false; });
                    }
                  },
                  child: const Text('Confirm'),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          value = (totalStockAssigned - totalStockReturned).toStringAsFixed(0) + ' Packs';
                          icon = Icons.assignment_turned_in;
                          color = Colors.blue;
                          break;
                        case 1:
                          title = 'Stock Value';
                          value = 'PKR ${totalTransactionValue.toStringAsFixed(2)}';
                          icon = Icons.shopping_cart;
                          color = Colors.green;
                          break;
                        case 2:
                          title = 'Amount Received';
                          value = 'PKR ${totalCashReceived.toStringAsFixed(2)}';
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
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                  Text(
                                    value,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                              initialDate: _filterStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
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
                                  : DateFormat('yyyy-MM-dd').format(_filterEndDate!)),
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
                              setState(() {
                                _filterEndDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Out (Packs)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Return (Packs)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Cash Received (PKR)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Total Amount (PKR)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Schemes', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredTransactions.map((transaction) {
                        return DataRow(
                          cells: [
                            DataCell(Text(DateFormat('yyyy-MM-dd')
                                .format(transaction.date.toDate()))),
                            DataCell(Text(transaction.type)),
                            DataCell(Text(transaction.brandName ?? '-')),
                            DataCell(Text(transaction.stockOutQuantity?.toStringAsFixed(0) ?? '-')),
                            DataCell(Text(transaction.stockReturnQuantity?.toStringAsFixed(0) ?? '-')),
                            DataCell(Text(transaction.cashReceived?.toStringAsFixed(2) ?? '-')),
                            DataCell(Text(transaction.calculatedPrice?.toStringAsFixed(2) ?? '-')),
                            DataCell(
                                Text(transaction.appliedSchemeNames?.join(', ') ?? '-')),
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
          }
      ),
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