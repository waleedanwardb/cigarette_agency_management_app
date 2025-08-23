// lib/UI/screens/stock/stock_main_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart'; // To access services
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

// Import screens this module will navigate to
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_stock_list_screen.dart'; // For Salesman Stock
import 'package:cigarette_agency_management_app/UI/screens/stock/factory_stock_screen.dart'; // New screen for Factory Stock
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';

// Import services and models
import 'package:cigarette_agency_management_app/services/product_service.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';
import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';

class StockMainScreen extends StatefulWidget {
  const StockMainScreen({super.key});

  @override
  State<StockMainScreen> createState() => _StockMainScreenState();
}

class _StockMainScreenState extends State<StockMainScreen> {
  int _selectedIndex = 2; // Assuming Stock is the 3rd item (index 2) in bottom nav

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

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

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
            // The rest of the screen's code remains the same as your original, but now the navigation is correct.
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
        onTap: (index) {
          if (index != _selectedIndex) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => [
                const HomeScreen(),
                const DashboardScreen(),
                const StockMainScreen(),
                const PaymentsMainScreen()
              ][index]),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}