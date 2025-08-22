import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

// Import screens this module will navigate to
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_stock_list_screen.dart'; // For Salesman Stock
import 'package:cigarette_agency_management_app/UI/screens/stock/factory_stock_screen.dart'; // New screen for Factory Stock

// Dummy data model for Stock Summary
class StockSummaryItem {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  StockSummaryItem({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
}

// Dummy data model for overall stock transactions to demonstrate filtering
class OverallStockTransaction {
  final String date;
  final String type; // e.g., 'Factory Receive', 'Salesman Out', 'Salesman Return'
  final String brand;
  final int quantity;

  OverallStockTransaction({
    required this.date,
    required this.type,
    required this.brand,
    required this.quantity,
  });
}


class StockMainScreen extends StatefulWidget {
  const StockMainScreen({super.key});

  @override
  State<StockMainScreen> createState() => _StockMainScreenState();
}

class _StockMainScreenState extends State<StockMainScreen> {
  int _selectedIndex = 2; // Assuming Stock is the 3rd item (index 2) in bottom nav

  // State variables for date filter
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  // Dummy data for Overall Stock Summary KPIs (these would ideally be dynamic)
  final List<StockSummaryItem> _overallStockSummary = [
    StockSummaryItem(
      title: 'Total Stock Received',
      value: '15,000',
      unit: 'Packs',
      icon: Icons.download_for_offline,
      color: Colors.green,
    ),
    StockSummaryItem(
      title: 'Current Godown Stock',
      value: '8,500',
      unit: 'Packs',
      icon: Icons.warehouse,
      color: Colors.blue,
    ),
    StockSummaryItem(
      title: 'Total Stock Out',
      value: '6,500',
      unit: 'Packs',
      icon: Icons.upload_file,
      color: Colors.orange,
    ),
    StockSummaryItem(
      title: 'Value of Stock',
      value: 'PKR 2.5M',
      unit: '',
      icon: Icons.monetization_on,
      color: Colors.purple,
    ),
  ];

  // Dummy granular data for overall stock transactions for filtering demonstration
  final List<OverallStockTransaction> _allOverallTransactions = [
    OverallStockTransaction(date: '2025-07-15', type: 'Factory Receive', brand: 'Marlboro', quantity: 1000),
    OverallStockTransaction(date: '2025-07-14', type: 'Salesman Out', brand: 'Dunhill', quantity: 50),
    OverallStockTransaction(date: '2025-07-12', type: 'Salesman Return', brand: 'Capstan', quantity: 5),
    OverallStockTransaction(date: '2025-07-10', type: 'Factory Receive', brand: 'Gold Leaf', quantity: 500),
    OverallStockTransaction(date: '2025-07-08', type: 'Salesman Out', brand: 'Pine', quantity: 20),
    OverallStockTransaction(date: '2025-06-20', type: 'Salesman Out', brand: 'Marlboro', quantity: 10), // For filter test
    OverallStockTransaction(date: '2025-06-18', type: 'Factory Receive', brand: 'Dunhill', quantity: 200), // For filter test
  ];

  // Filtered transactions getter for the report
  List<OverallStockTransaction> get _filteredOverallTransactions {
    return _allOverallTransactions.where((transaction) {
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
    // Implement navigation for bottom nav if this screen is directly on it
  }

  void _navigateToSalesmanStock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesmanStockListScreen()),
    );
  }

  void _navigateToFactoryStock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FactoryStockScreen()),
    );
  }

  void _generateReport() {
    // In a real app, you would use _filteredOverallTransactions to generate the report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Generating report for ${_filteredOverallTransactions.length} transactions in Excel/PDF... (Placeholder)')),
    );
    // You would use packages like 'excel', 'pdf', or send data to a backend for generation.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock Management',
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
            const Text(
              'Overall Stock Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.3,
              ),
              itemCount: _overallStockSummary.length,
              itemBuilder: (context, index) {
                final item = _overallStockSummary[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: item.color.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          item.icon,
                          color: Colors.white,
                          size: 30,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${item.value} ${item.unit}',
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
              },
            ),
            const SizedBox(height: 30),

            const Text(
              'Stock Operations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToSalesmanStock,
                    icon: const Icon(Icons.group),
                    label: const Text('Manage Salesman Stock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToFactoryStock,
                    icon: const Icon(Icons.factory),
                    label: const Text('Manage Factory Stock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Date Filter Options ---
            const Text(
              'Report Filter',
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

            // --- GENERATE REPORT BUTTON ---
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}