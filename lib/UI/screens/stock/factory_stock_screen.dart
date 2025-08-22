import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import models
import 'package:cigarette_agency_management_app/models/brand.dart';
import 'package:cigarette_agency_management_app/models/product.dart'; // Ensure Product is imported correctly

// Import other main screens for BottomNavigationBar navigation
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart'; // Corrected path (if needed)


// Dummy data model for Factory Transaction (unchanged)
class FactoryTransaction {
  final String date;
  final String type; // e.g., 'Received', 'Dispatched to Market', 'Sold from Godown'
  final String brandName;
  final String productName; // Added product name
  final int quantity;
  final String reference; // e.g., Invoice # or Salesman Name
  final double? value; // Optional: monetary value
  final double? paymentDue; // For payment tracking
  final String? paymentStatus; // e.g., 'Paid', 'Partially Paid', 'Due'
  final double? remainingAmount; // Calculated

  FactoryTransaction({
    required this.date,
    required this.type,
    required this.brandName,
    required this.productName,
    required this.quantity,
    required this.reference,
    this.value,
    this.paymentDue,
    this.paymentStatus,
    this.remainingAmount,
  });
}

class FactoryStockScreen extends StatefulWidget {
  const FactoryStockScreen({super.key});

  @override
  State<FactoryStockScreen> createState() => _FactoryStockScreenState();
}

class _FactoryStockScreenState extends State<FactoryStockScreen> {
  Brand? _selectedBrand;
  List<Product> _allProducts = []; // Will hold products

  // Dummy factory stock summaries per brand (would be calculated from transactions in a real app)
  final Map<String, Map<String, dynamic>> _brandFactorySummaries = const {
    'Marlboro': {'totalReceived': 2500, 'currentStock': 1500, 'totalValue': 375000.0, 'paymentDue': 0.0},
    'Dunhill': {'totalReceived': 1000, 'currentStock': 800, 'totalValue': 224000.0, 'paymentDue': 0.0},
    'Capstan': {'totalReceived': 1500, 'currentStock': 1200, 'totalValue': 216000.0, 'paymentDue': 90000.0},
  };

  // Dummy data for Factory Transactions (unchanged, still uses old dummy values)
  final List<FactoryTransaction> _recentFactoryTransactions = [
    FactoryTransaction(date: '2025-07-15', type: 'Received', brandName: 'Marlboro', productName: 'Red 20s', quantity: 1000, reference: 'INV-001', value: 250000.0, paymentDue: 250000.0, paymentStatus: 'Paid', remainingAmount: 0.0),
    FactoryTransaction(date: '2025-07-14', type: 'Sold from Godown', brandName: 'Dunhill', productName: 'Blue 20s', quantity: 200, reference: 'Direct Sale', value: 56000.0),
    FactoryTransaction(date: '2025-07-12', type: 'Received', brandName: 'Capstan', productName: 'Filter 20s', quantity: 500, reference: 'INV-002', value: 90000.0, paymentDue: 90000.0, paymentStatus: 'Due', remainingAmount: 90000.0),
    FactoryTransaction(date: '2025-07-10', type: 'Dispatched to Market', brandName: 'Gold Leaf', productName: 'Green 20s', quantity: 300, reference: 'Salesman-XYZ'),
  ];

  // List of main screens for BottomNavigationBar navigation (unchanged)
  final List<Widget> _bottomNavScreens = const [ // Using const for this list
    HomeScreen(),
    DashboardScreen(),
    StockMainScreen(),
    PaymentsMainScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize _allProducts here for demonstration purposes using Product.dummyProducts.
    // This is crucial for the Product dropdown in the dialog.
    _allProducts = Product.dummyProducts;
  }

  void _recordNewFactoryReceipt() {
    _showAddFactoryStockDialog();
  }

  Future<void> _showAddFactoryStockDialog() async {
    final formKey = GlobalKey<FormState>(); // FIX: Renamed _formKey to formKey
    Brand? dialogSelectedBrand = _selectedBrand;
    Product? dialogSelectedProduct;
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController invoicePriceController = TextEditingController();
    final TextEditingController paymentPaidController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();
    DateTime? receiptDate = DateTime.now();

    // These variables need to be local to the dialog's StatefulBuilder's scope
    double _calculatedTotalPrice = 0.0;
    double _calculatedRemainingAmount = 0.0;
    String _paymentStatus = 'Due';

    // Helper function to update calculations for the dialog
    void updateCalculationsInDialog() {
      double quantity = double.tryParse(quantityController.text) ?? 0.0;
      double productPrice = dialogSelectedProduct?.price ?? 0.0;
      double invoicePrice = double.tryParse(invoicePriceController.text) ?? 0.0;
      double paymentPaid = double.tryParse(paymentPaidController.text) ?? 0.0;

      _calculatedTotalPrice = quantity * productPrice;
      _calculatedRemainingAmount = invoicePrice - paymentPaid;
      if (_calculatedRemainingAmount <= 0) {
        _paymentStatus = 'Paid';
      } else if (paymentPaid > 0) {
        _paymentStatus = 'Partially Paid';
      } else {
        _paymentStatus = 'Due';
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            final List<Product> productsOfSelectedBrand = dialogSelectedBrand != null
                ? _allProducts.where((p) => p.brand == dialogSelectedBrand!.name).toList()
                : [];

            // If a brand is selected but no product, and productsOfSelectedBrand is not empty,
            // default to the first product to avoid dropdown error.
            if (dialogSelectedBrand != null && dialogSelectedProduct == null && productsOfSelectedBrand.isNotEmpty) {
              dialogSelectedProduct = productsOfSelectedBrand.first;
              // Initial calculation after defaulting product
              updateCalculationsInDialog(); // Use dialog-specific calculations
            }

            return AlertDialog(
              title: const Text('Record Factory Receipt'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // FIX: Use formKey
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Choose Brand
                      DropdownButtonFormField<Brand>(
                        decoration: const InputDecoration(
                          labelText: 'Choose Brand',
                          border: OutlineInputBorder(),
                        ),
                        value: dialogSelectedBrand,
                        items: Brand.dummyBrands.map((brand) {
                          return DropdownMenuItem<Brand>(
                            value: brand,
                            child: Text(brand.name),
                          );
                        }).toList(),
                        onChanged: (Brand? newValue) {
                          setStateInDialog(() {
                            dialogSelectedBrand = newValue;
                            dialogSelectedProduct = null; // Reset product when brand changes
                            updateCalculationsInDialog(); // Use dialog-specific calculations
                          });
                        },
                        validator: (value) => value == null ? 'Select a brand' : null,
                      ),
                      const SizedBox(height: 15),

                      // Choose Product of that Brand
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(
                          labelText: 'Choose Product',
                          border: OutlineInputBorder(),
                        ),
                        value: dialogSelectedProduct,
                        items: productsOfSelectedBrand.map((product) {
                          return DropdownMenuItem<Product>(
                            value: product,
                            child: Text(product.name),
                          );
                        }).toList(),
                        onChanged: (Product? newValue) {
                          setStateInDialog(() {
                            dialogSelectedProduct = newValue;
                            updateCalculationsInDialog(); // Use dialog-specific calculations
                          });
                        },
                        validator: (value) => value == null ? 'Select a product' : null,
                        isExpanded: true,
                        hint: Text(dialogSelectedBrand == null ? 'Select a brand first' : 'Select a product'),
                      ),
                      const SizedBox(height: 15),

                      // Amount of Stock (Quantity Received)
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity Received (Packs)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setStateInDialog(() {
                            updateCalculationsInDialog(); // Use dialog-specific calculations
                          });
                        },
                        validator: (value) => (value == null || int.tryParse(value) == null || int.parse(value) <= 0) ? 'Enter valid quantity' : null,
                      ),
                      const SizedBox(height: 15),

                      // Total Price (Calculated)
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: 'PKR ${_calculatedTotalPrice.toStringAsFixed(2)}'), // Use _calculatedTotalPrice
                        decoration: InputDecoration( // Removed 'const' if present
                          labelText: 'Calculated Total Price',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.grey[100],
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Payment Due (Actual invoice amount)
                      TextFormField(
                        controller: invoicePriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Total Amount (PKR)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setStateInDialog(() { updateCalculationsInDialog(); }); // Use dialog-specific calculations
                        },
                        validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter invoice amount' : null,
                      ),
                      const SizedBox(height: 15),

                      // Payment Paid (Amount paid so far)
                      TextFormField(
                        controller: paymentPaidController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount Paid (PKR)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setStateInDialog(() { updateCalculationsInDialog(); }); // Use dialog-specific calculations
                        },
                        validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter paid amount (0 if none)' : null,
                      ),
                      const SizedBox(height: 15),

                      // Payment Status (Automatic)
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _paymentStatus), // Use _paymentStatus
                        decoration: InputDecoration( // Removed 'const' if present
                          labelText: 'Payment Status',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.lightGreen[50],
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Remaining Amount (Automatic)
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: 'PKR ${_calculatedRemainingAmount.toStringAsFixed(2)}'), // Use _calculatedRemainingAmount
                        decoration: InputDecoration( // Removed 'const' if present
                          labelText: 'Remaining Amount',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.orange[50],
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Reference/Invoice Number
                      TextFormField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference / Invoice #',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Enter reference' : null,
                      ),
                      const SizedBox(height: 15),

                      // Date of Receipt
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(receiptDate!)),
                        decoration: const InputDecoration(
                          labelText: 'Date of Receipt',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: receiptDate!,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != receiptDate) {
                            setStateInDialog(() {
                              receiptDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Record Receipt'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) { // FIX: Use formKey
                      // Simulate recording new factory receipt
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Recorded: ${quantityController.text} packs of ${dialogSelectedProduct!.name} from ${dialogSelectedBrand!.name}. Status: $_paymentStatus')), // Use _paymentStatus
                      );
                      Navigator.of(dialogContext).pop();
                      // Add to _recentFactoryTransactions or send to backend
                      setState(() { // Use outer setState to update main screen's list
                        _recentFactoryTransactions.insert(0, FactoryTransaction(
                          date: DateFormat('yyyy-MM-dd').format(receiptDate!),
                          type: 'Received',
                          brandName: dialogSelectedBrand!.name,
                          productName: dialogSelectedProduct!.name,
                          quantity: int.parse(quantityController.text),
                          reference: referenceController.text,
                          value: _calculatedTotalPrice, // Use _calculatedTotalPrice
                          paymentDue: double.parse(invoicePriceController.text),
                          paymentStatus: _paymentStatus, // Use _paymentStatus
                          remainingAmount: _calculatedRemainingAmount, // Use _calculatedRemainingAmount
                        ));
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
    // Dispose controllers after the dialog is closed
    quantityController.dispose();
    invoicePriceController.dispose();
    paymentPaidController.dispose();
    referenceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For now, populate _allProducts from a static source if it's empty.
    if (_allProducts.isEmpty) { // Check only if empty to avoid re-initializing on rebuilds
      _allProducts = Product.dummyProducts; // Access static dummy products
    }

    // Filter transactions to show only those for selected brand (if any)
    final List<FactoryTransaction> _displayedTransactions = _selectedBrand == null
        ? _recentFactoryTransactions // Show all if no brand selected
        : _recentFactoryTransactions.where((t) => t.brandName == _selectedBrand!.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Factory Stock Management',
          style: TextStyle(fontSize: 18),
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
            // Brand Selection Dropdown
            DropdownButtonFormField<Brand>(
              decoration: const InputDecoration(
                labelText: 'Select Brand',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              value: _selectedBrand,
              items: Brand.dummyBrands.map((brand) {
                return DropdownMenuItem<Brand>(
                  value: brand,
                  child: Text(brand.name),
                );
              }).toList(),
              onChanged: (Brand? newValue) {
                setState(() {
                  _selectedBrand = newValue;
                });
              },
              hint: const Text('Select a brand to view/add stock'),
            ),
            const SizedBox(height: 20),

            // Conditional Content based on Brand Selection
            _selectedBrand == null
                ? Column( // Initial state: sexy icon in middle
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Icon(
                    Icons.warehouse_outlined, // Sexy related icon
                    size: 120,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Select a brand to manage its factory stock.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
                : Column( // Content when a brand is selected
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary for ${_selectedBrand!.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                // Display factory stock summaries for the selected brand
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.3,
                  children: [
                    _buildSummaryCard(
                        'Total Received',
                        (_brandFactorySummaries[_selectedBrand!.name]?['totalReceived']?.toStringAsFixed(0) ?? '0'),
                        Icons.inbox, Colors.blue),
                    _buildSummaryCard(
                        'Current Stock',
                        (_brandFactorySummaries[_selectedBrand!.name]?['currentStock']?.toStringAsFixed(0) ?? '0'),
                        Icons.layers, Colors.teal),
                    _buildSummaryCard(
                        'Total Value',
                        'PKR ${(_brandFactorySummaries[_selectedBrand!.name]?['totalValue']?.toStringAsFixed(2) ?? '0.00')}',
                        Icons.monetization_on, Colors.purple),
                    _buildSummaryCard(
                        'Payment Due',
                        'PKR ${(_brandFactorySummaries[_selectedBrand!.name]?['paymentDue']?.toStringAsFixed(2) ?? '0.00')}',
                        Icons.credit_card_off, Colors.red),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _recordNewFactoryReceipt,
                    icon: const Icon(Icons.add_box),
                    label: Text('Record New Stock for ${_selectedBrand!.name}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
                      DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ref', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Remaining (PKR)', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _displayedTransactions.map((transaction) {
                      return DataRow(
                        cells: [
                          DataCell(Text(transaction.date)),
                          DataCell(Text(transaction.type)),
                          DataCell(Text(transaction.productName)),
                          DataCell(Text(transaction.quantity.toString())),
                          DataCell(Text(transaction.reference)),
                          DataCell(Text(transaction.paymentStatus ?? '-')),
                          DataCell(Text(transaction.remainingAmount?.toStringAsFixed(2) ?? '-')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
        currentIndex: 2, // Stock is index 2 in our main nav
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index != 2) { // If not Stock (current screen)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => _bottomNavScreens[index]),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Helper method for summary cards
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: color.withOpacity(0.8), // This will trigger the deprecation warning
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}