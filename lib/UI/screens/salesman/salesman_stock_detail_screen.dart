import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// Import models
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/brand.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart'; // Import Scheme model
import 'package:cigarette_agency_management_app/models/company_claim.dart'; // Import CompanyClaim model & global list
import 'package:cigarette_agency_management_app/models/product.dart'; // Import Product model

// Import main screen paths for BottomNavigationBar navigation (ensure these paths are correct)
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';


// --- UPDATED SalesmanTransaction class with new fields ---
class SalesmanTransaction {
  final String date;
  final String type;
  final String? productName;
  final double? stockGivenAmount; // Renamed from stockOutAmount
  final double? transactionValue; // NEW: The main monetary amount of this transaction
  final double? stockReturnAmount;
  final double? cashCollected; // Renamed from cashGiven
  final double? schemeDiscount; // Renamed from totalSchemeDiscount
  final double? arrearAmount; // NEW: For tracking outstanding amounts

  SalesmanTransaction({
    required this.date,
    required this.type,
    this.productName,
    this.stockGivenAmount,
    this.transactionValue,
    this.stockReturnAmount,
    this.cashCollected,
    this.schemeDiscount,
    this.arrearAmount,
  });
}

class SalesmanStockDetailScreen extends StatefulWidget {
  final Salesman salesman;

  const SalesmanStockDetailScreen({super.key, required this.salesman});

  @override
  State<SalesmanStockDetailScreen> createState() => _SalesmanStockDetailScreenState();
}

class _SalesmanStockDetailScreenState extends State<SalesmanStockDetailScreen> {
  int _selectedIndex = 2;

  double _stockAssigned = 1000.0;
  double _stockSold = 780.20;
  double _amountReceived = 780.20;
  double _balanceDue = 6000.0;

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  // --- UPDATED Dummy data for recent transactions to fit new model ---
  final List<SalesmanTransaction> _allTransactions = [
    SalesmanTransaction(
        date: '2025-08-04',
        type: 'Stock Out',
        productName: 'Marlboro Red 20s',
        stockGivenAmount: 100.0,
        transactionValue: 1500.0,
        schemeDiscount: 50.0,
        arrearAmount: 0.0),
    SalesmanTransaction(
        date: '2025-08-04',
        type: 'Stock Out',
        productName: 'Capstan Filter 20s',
        stockGivenAmount: 50.0,
        transactionValue: 1300.0,
        schemeDiscount: 0.0,
        arrearAmount: 0.0),
    SalesmanTransaction(
        date: '2025-08-04',
        type: 'Stock Out',
        productName: 'Dunhill Blue 20s',
        stockGivenAmount: 70.0,
        transactionValue: 4500.0,
        schemeDiscount: 0.0,
        arrearAmount: 0.0),
    SalesmanTransaction(
        date: '2025-08-04',
        type: 'Stock Out',
        productName: 'Gold Leaf Red and white',
        stockGivenAmount: 90.0,
        transactionValue: 1800.0,
        schemeDiscount: 0.0,
        arrearAmount: 0.0),
    SalesmanTransaction(
        date: '2025-07-15',
        type: 'Cash Collected',
        productName: '-',
        cashCollected: 5000.0,
        transactionValue: 5000.0,
        schemeDiscount: 0.0,
        arrearAmount: -5000.0), // Example: negative arrear to reduce balance
  ];

  List<SalesmanTransaction> get _filteredTransactions {
    return _allTransactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction.date);
      bool matchesStartDate = _filterStartDate == null ||
          transactionDate.isAtSameMomentAs(_filterStartDate!) ||
          transactionDate.isAfter(_filterStartDate!);
      bool matchesEndDate = _filterEndDate == null ||
          transactionDate.isAtSameMomentAs(_filterEndDate!) ||
          transactionDate.isBefore(_filterEndDate!);
      return matchesStartDate && matchesEndDate;
    }).toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<List<Scheme>?> _showMultiSelectSchemeDialog(BuildContext context, List<Scheme> currentSelectedSchemes) async {
    final List<Scheme> allActiveSchemes = Scheme.dummySchemes.where((s) => s.isActive).toList();
    final List<Scheme> tempSelectedSchemes = List.from(currentSelectedSchemes);

    return await showDialog<List<Scheme>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Schemes to Apply'),
          content: SingleChildScrollView(
            child: ListBody(
              children: allActiveSchemes.map((scheme) {
                bool isSelected = tempSelectedSchemes.any((s) => s.id == scheme.id);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text('${scheme.name} (PKR ${scheme.amount.toStringAsFixed(2)}/pack)'),
                  subtitle: Text(scheme.description),
                  onChanged: (bool? checked) {
                    setState(() {
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

  Future<void> _showRecordCashDialog() async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Record Cash Collected'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (PKR)', border: OutlineInputBorder()),
                    validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0) ? 'Enter valid amount' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate!)),
                    decoration: const InputDecoration(
                      labelText: 'Date Collected',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context, initialDate: selectedDate!, firstDate: DateTime(2000), lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() { selectedDate = picked; });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () {
              Navigator.of(dialogContext).pop();
            }),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _allTransactions.insert(0, SalesmanTransaction(
                      date: DateFormat('yyyy-MM-dd').format(selectedDate!),
                      type: 'Cash Collected',
                      cashCollected: amount,
                      transactionValue: amount,
                      productName: '-',
                      schemeDiscount: 0.0,
                      arrearAmount: -amount,
                    ));
                    _amountReceived += amount;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PKR ${amount.toStringAsFixed(2)} collected!')));
                }
              },
            ),
          ],
        );
      },
    ).then((_) { amountController.dispose(); descriptionController.dispose(); });
  }

  Future<void> _showRecordArrearDialog() async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Record Arrear'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (PKR)', border: OutlineInputBorder()),
                    validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0) ? 'Enter valid amount' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 2,
                    validator: (value) => value!.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate!)),
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context, initialDate: selectedDate!, firstDate: DateTime(2000), lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() { selectedDate = picked; });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () {
              Navigator.of(dialogContext).pop();
            }),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _allTransactions.insert(0, SalesmanTransaction(
                      date: DateFormat('yyyy-MM-dd').format(selectedDate!),
                      type: 'Arrear',
                      arrearAmount: amount,
                      transactionValue: amount,
                      productName: '-',
                      schemeDiscount: 0.0,
                    ));
                    _balanceDue += amount;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arrear of PKR ${amount.toStringAsFixed(2)} recorded!')));
                }
              },
            ),
          ],
        );
      },
    ).then((_) { amountController.dispose(); descriptionController.dispose(); });
  }

  Future<void> _showStockOutDialog() async {
    final Map<String, TextEditingController> quantityControllers = {};
    for (var product in Product.dummyProducts) {
      quantityControllers[product.id] = TextEditingController();
    }

    final TextEditingController selectedDateController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    selectedDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);

    double _dialogCalculatedGrossPrice = 0.0;
    double _dialogTotalSchemeDiscount = 0.0;
    double _dialogFinalPriceAfterScheme = 0.0;
    List<String> _appliedSchemeNames = [];
    Map<String, double> _dialogProductSchemeDiscounts = {};

    void updateCalculations() {
      _dialogCalculatedGrossPrice = 0.0;
      _dialogTotalSchemeDiscount = 0.0;
      _dialogFinalPriceAfterScheme = 0.0;
      _appliedSchemeNames = [];
      _dialogProductSchemeDiscounts = {};

      for (var product in Product.dummyProducts) {
        double quantity = double.tryParse(quantityControllers[product.id]?.text ?? '') ?? 0.0;
        if (quantity > 0) {
          _dialogCalculatedGrossPrice += (quantity * product.price);

          double productSchemeDiscount = 0.0;
          List<Scheme> applicableSchemes = Scheme.dummySchemes.where((s) {
            return s.isActive &&
                (s.applicableProducts == 'All Cigarette Packs' ||
                    s.applicableProducts.contains(product.brand) ||
                    s.applicableProducts.contains(product.name));
          }).toList();

          for (var scheme in applicableSchemes) {
            productSchemeDiscount += scheme.amount * quantity;
            if (!_appliedSchemeNames.contains(scheme.name)) {
              _appliedSchemeNames.add(scheme.name);
            }
          }
          _dialogTotalSchemeDiscount += productSchemeDiscount;
          _dialogProductSchemeDiscounts[product.name] = productSchemeDiscount;
        }
      }
      _dialogFinalPriceAfterScheme = _dialogCalculatedGrossPrice - _dialogTotalSchemeDiscount;
      if (_dialogFinalPriceAfterScheme < 0) _dialogFinalPriceAfterScheme = 0;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setStateInDialog(() { updateCalculations(); });
              }
            });

            return AlertDialog(
              title: const Text('Record Stock Out (All Products)'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        readOnly: true,
                        controller: selectedDateController,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate!,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
                            setStateInDialog(() { selectedDate = picked; });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Enter quantities for products:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: Product.dummyProducts.length,
                        itemBuilder: (context, index) {
                          final product = Product.dummyProducts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${product.brand} - ${product.name}',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: quantityControllers[product.id],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Qty',
                                      hintText: 'PKR ${product.price.toStringAsFixed(2)}/pack',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    ),
                                    onChanged: (value) {
                                      setStateInDialog(() { updateCalculations(); });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: 'Gross: PKR ${_dialogCalculatedGrossPrice.toStringAsFixed(2)}'),
                        decoration: InputDecoration(
                          labelText: 'Total Gross Price',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.grey[100],
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: 'Total Scheme Discount: PKR ${_dialogTotalSchemeDiscount.toStringAsFixed(2)}'),
                        decoration: InputDecoration(
                          labelText: 'Total Scheme Discount',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.orange[50],
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                      if (_dialogProductSchemeDiscounts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Discounts by Product:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              ..._dialogProductSchemeDiscounts.entries.map((entry) => Text(
                                '${entry.key}: PKR ${entry.value.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              )).toList(),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: 'Final: PKR ${_dialogFinalPriceAfterScheme.toStringAsFixed(2)}'),
                        decoration: InputDecoration(
                          labelText: 'Final Price (After Schemes)',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.lightGreen[50],
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                      if (_appliedSchemeNames.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Schemes Applied: ${_appliedSchemeNames.join(', ')}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    quantityControllers.forEach((key, controller) => controller.dispose());
                    selectedDateController.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Confirm Stock Out'),
                  onPressed: () {
                    double totalPacks = 0.0;
                    Map<String, double> stockedOutProducts = {};
                    List<String> stockedOutProductNames = [];

                    for(var entry in quantityControllers.entries) {
                      double qty = double.tryParse(entry.value.text) ?? 0.0;
                      if (qty > 0) {
                        totalPacks += qty;
                        stockedOutProducts[entry.key] = qty;
                        Product? product = Product.dummyProducts.firstWhere((p) => p.id == entry.key);
                        if (product != null) {
                          stockedOutProductNames.add('${product.brand} ${product.name}');
                        }
                      }
                    }

                    if (totalPacks == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter quantity for at least one product.')));
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    double totalTransactionValue = _dialogCalculatedGrossPrice;
                    double totalSchemeAmount = _dialogTotalSchemeDiscount;

                    setState(() {
                      _allTransactions.insert(0, SalesmanTransaction(
                        date: DateFormat('yyyy-MM-dd').format(selectedDate!),
                        type: 'Stock Out',
                        productName: stockedOutProductNames.join(', '),
                        stockGivenAmount: totalPacks,
                        transactionValue: totalTransactionValue,
                        schemeDiscount: totalSchemeAmount,
                      ));
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showStockReturnDialog() async {
    final Map<String, TextEditingController> returnQuantityControllers = {};
    final List<Product> productsSalesmanHasStockedOut = Product.dummyProducts.where((p) {
      return _allTransactions.any((t) => t.type == 'Stock Out' && t.productName != null && t.productName!.contains(p.name));
    }).toList();

    for (var product in productsSalesmanHasStockedOut) {
      returnQuantityControllers[product.id] = TextEditingController();
    }

    final TextEditingController selectedReturnDateController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    selectedReturnDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);

    double _dialogCalculatedReturnTotalValue = 0.0;
    double _dialogTotalSchemeDiscountForReturn = 0.0;
    List<String> _appliedSchemeNamesForReturn = [];
    Map<String, double> _dialogProductReturnSchemeDiscounts = {};

    void updateCalculations() {
      _dialogCalculatedReturnTotalValue = 0.0;
      _dialogTotalSchemeDiscountForReturn = 0.0;
      _appliedSchemeNamesForReturn = [];
      _dialogProductReturnSchemeDiscounts = {};

      for (var product in productsSalesmanHasStockedOut) {
        double quantity = double.tryParse(returnQuantityControllers[product.id]?.text ?? '') ?? 0.0;
        if (quantity > 0) {
          _dialogCalculatedReturnTotalValue += (quantity * product.price);

          double productSchemeDiscount = 0.0;
          List<Scheme> applicableSchemes = Scheme.dummySchemes.where((s) {
            return s.isActive &&
                (s.applicableProducts == 'All Cigarette Packs' ||
                    s.applicableProducts.contains(product.brand) ||
                    s.applicableProducts.contains(product.name));
          }).toList();

          for (var scheme in applicableSchemes) {
            productSchemeDiscount += scheme.amount * quantity;
            if (!_appliedSchemeNamesForReturn.contains(scheme.name)) {
              _appliedSchemeNamesForReturn.add(scheme.name);
            }
          }
          _dialogTotalSchemeDiscountForReturn += productSchemeDiscount;
          _dialogProductReturnSchemeDiscounts[product.name] = productSchemeDiscount;
        }
      }

      _dialogCalculatedReturnTotalValue = _dialogCalculatedReturnTotalValue - _dialogTotalSchemeDiscountForReturn;
      if (_dialogCalculatedReturnTotalValue < 0) _dialogCalculatedReturnTotalValue = 0;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setStateInDialog(() { updateCalculations(); });
              }
            });

            return AlertDialog(
                title: const Text('Record Stock Return (All Products)'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          readOnly: true,
                          controller: selectedReturnDateController,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate!,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != selectedDate) {
                              setStateInDialog(() { selectedDate = picked; });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text('Enter quantities for products to return:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),

                        productsSalesmanHasStockedOut.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No outstanding stock to return.',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: productsSalesmanHasStockedOut.length,
                          itemBuilder: (context, index) {
                            final product = productsSalesmanHasStockedOut[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${product.brand} - ${product.name}',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: returnQuantityControllers[product.id],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Qty',
                                        hintText: 'PKR ${product.price.toStringAsFixed(2)}/pack',
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      ),
                                      onChanged: (value) {
                                        setStateInDialog(() { updateCalculations(); });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: 'Total Return Value: PKR ${_dialogCalculatedReturnTotalValue.toStringAsFixed(2)}'),
                          decoration: InputDecoration(
                            labelText: 'Total Return Value',
                            border: const OutlineInputBorder(),
                            fillColor: Colors.grey[100],
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: 'Total Scheme Discount: PKR ${_dialogTotalSchemeDiscountForReturn.toStringAsFixed(2)}'),
                          decoration: InputDecoration(
                            labelText: 'Total Scheme Discount (Return)',
                            border: const OutlineInputBorder(),
                            fillColor: Colors.orange[50],
                            filled: true,
                          ),
                        ),
                        if (_dialogProductReturnSchemeDiscounts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Discounts (Return) by Product:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                ..._dialogProductReturnSchemeDiscounts.entries.map((entry) => Text(
                                  '${entry.key}: PKR ${entry.value.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                )).toList(),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        const Text(
                          'Note: Returns will be adjusted against assigned brands and financial records.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                ),
              actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  returnQuantityControllers.forEach((key, controller) => controller.dispose());
                  selectedReturnDateController.dispose();
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Confirm Return'),
                onPressed: () {
                  double totalPacksReturned = 0.0;
                  Map<String, double> returnedProducts = {};
                  List<String> returnedProductNames = [];

                  for(var entry in returnQuantityControllers.entries) {
                    double qty = double.tryParse(entry.value.text) ?? 0.0;
                    if (qty > 0) {
                      totalPacksReturned += qty;
                      returnedProducts[entry.key] = qty;
                      Product? product = Product.dummyProducts.firstWhere((p) => p.id == entry.key);
                      if (product != null) {
                        returnedProductNames.add('${product.brand} ${product.name}');
                      }
                    }
                  }

                  if (totalPacksReturned == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter quantity for at least one product to return.')));
                    return;
                  }

                  Navigator.of(dialogContext).pop();

                  double totalTransactionValue = _dialogCalculatedReturnTotalValue;
                  double totalSchemeAmount = _dialogTotalSchemeDiscountForReturn;

                  setState(() {
                    _allTransactions.insert(0, SalesmanTransaction(
                      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      type: 'Stock Return',
                      productName: returnedProductNames.join(', '),
                      stockReturnAmount: totalPacksReturned,
                      transactionValue: totalTransactionValue,
                      schemeDiscount: totalSchemeAmount,
                    ));
                  });

                  if (totalSchemeAmount > 0) {
                    String primaryCompanyName = 'N/A';
                    String primaryProductName = 'N/A';
                    if (_appliedSchemeNamesForReturn.isNotEmpty) {
                      Scheme? firstAppliedScheme = Scheme.dummySchemes.firstWhere((s) => _appliedSchemeNamesForReturn.contains(s.name), orElse: () => Scheme(id: '', name: '', type: '', amount: 0, isActive: false, validFrom: DateTime.now(), validTo: DateTime.now(), companyName: '', productName: '', description: '', applicableProducts: ''));
                      primaryCompanyName = firstAppliedScheme.companyName;
                      primaryProductName = firstAppliedScheme.productName;
                    }

                    _recordCompanySchemeClaim(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      type: 'Scheme Amount (Return)',
                      productName: primaryProductName,
                      companyName: primaryCompanyName,
                      schemeNames: _appliedSchemeNamesForReturn,
                      totalAmount: totalSchemeAmount,
                      packsCount: totalPacksReturned,
                      date: DateTime.now(),
                      transactionType: 'Stock Return',
                    );
                  }
                },
              ),
            ],
            );
            },
        );
      },
    );
  }

  void _recordCompanySchemeClaim({
    required String id,
    required String type,
    String? brandName,
    required String productName,
    required String companyName,
    required List<String> schemeNames,
    required double totalAmount,
    required double packsCount,
    required DateTime date,
    required String transactionType,
  }) {
    String descriptionLabel =
        'Brand: ${brandName ?? 'N/A'}, Product: $productName, Schemes: ${schemeNames.join(', ')}, Total Amt: PKR ${totalAmount.toStringAsFixed(2)}, Packs: ${packsCount.toStringAsFixed(0)} (Type: $transactionType, Co: $companyName)';

    CompanyClaim newClaim = CompanyClaim(
      id: id,
      type: type,
      description: descriptionLabel,
      amount: totalAmount,
      status: 'Pending',
      dateIncurred: date,
      brandName: brandName,
      productName: productName,
      schemeNames: schemeNames,
      packsAffected: packsCount,
      companyName: companyName,
    );

    globalCompanyClaims.insert(0, newClaim);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheme Claim Recorded! Total: PKR ${totalAmount.toStringAsFixed(2)}'),
        duration: const Duration(seconds: 3),
      ),
    );
    print('Company Claim Recorded: ${newClaim.description}');
  }


  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Generating report for ${_filteredTransactions.length} transactions in Excel/PDF... (Placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> productsSalesmanHasStockedOut = Product.dummyProducts.where((p) {
      return _allTransactions.any((t) => t.type == 'Stock Out' && t.productName != null && t.productName!.contains(p.name));
    }).toList();

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
      body: SingleChildScrollView(
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
                    value = _stockAssigned.toStringAsFixed(0);
                    icon = Icons.assignment_turned_in;
                    color = Colors.blue;
                    break;
                  case 1:
                    title = 'Stock Sold';
                    value = _stockSold.toStringAsFixed(0);
                    icon = Icons.shopping_cart;
                    color = Colors.green;
                    break;
                  case 2:
                    title = 'Amount Received';
                    value = 'PKR ${_amountReceived.toStringAsFixed(2)}';
                    icon = Icons.payments;
                    color = Colors.orange;
                    break;
                  case 3:
                    title = 'Balance Due';
                    value = 'PKR ${_balanceDue.toStringAsFixed(2)}';
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (productsSalesmanHasStockedOut.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No stock has been assigned to return.')),
                        );
                      } else {
                        _showStockReturnDialog();
                      }
                    },
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('Record Stock Return'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showRecordCashDialog,
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('Record Cash Collected'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showRecordArrearDialog,
                    icon: const Icon(Icons.error_outline),
                    label: const Text('Record Arrear'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.orange[600],
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
                    controller: TextEditingController(text: _filterStartDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterStartDate!)),
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
                    controller: TextEditingController(text: _filterEndDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterEndDate!)),
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
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Stock Given', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Stock Return', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Cash Collected', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Scheme Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Arrears', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _filteredTransactions.map((transaction) {
                  return DataRow(
                    cells: [
                      DataCell(Text(transaction.date)),
                      DataCell(Text(transaction.productName ?? '-')),
                      DataCell(Text(transaction.stockGivenAmount?.toStringAsFixed(0) ?? '-')),
                      DataCell(Text(transaction.transactionValue?.toStringAsFixed(2) ?? '-')),
                      DataCell(Text(transaction.stockReturnAmount?.toStringAsFixed(0) ?? '-')),
                      DataCell(Text(transaction.cashCollected?.toStringAsFixed(2) ?? '-')),
                      DataCell(Text(transaction.schemeDiscount?.toStringAsFixed(2) ?? '-')),
                      DataCell(Text(transaction.arrearAmount?.toStringAsFixed(2) ?? '-')),
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
        onTap: (index) {
          if (index != _selectedIndex) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => [const HomeScreen(), const DashboardScreen(), const StockMainScreen(), const PaymentsMainScreen()][index]),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'Stock Out':
        return Icons.outbox;
      case 'Stock Return':
        return Icons.assignment_return;
      case 'Stock Sale':
        return Icons.point_of_sale;
      case 'Amount Received':
        return Icons.payments;
      default:
        return Icons.info_outline;
    }
  }
}