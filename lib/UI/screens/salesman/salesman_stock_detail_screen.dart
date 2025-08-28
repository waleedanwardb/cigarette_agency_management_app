// lib/UI/screens/salesman/salesman_stock_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';

// Import new modular screens
import 'package:cigarette_agency_management_app/UI/screens/salesman/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/stock_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/transactions_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';

// NEW: Import the MT screen
import 'package:cigarette_agency_management_app/UI/screens/salesman/mt_screen.dart';


class SalesmanStockDetailScreen extends StatefulWidget {
  final Salesman salesman;

  const SalesmanStockDetailScreen({super.key, required this.salesman});

  @override
  State<SalesmanStockDetailScreen> createState() =>
      _SalesmanStockDetailScreenState();
}

class _SalesmanStockDetailScreenState extends State<SalesmanStockDetailScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesmanService = Provider.of<SalesmanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.salesman.name}\'s Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to salesman profile
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

          final List<Widget> screens = [
            DashboardScreen(salesman: widget.salesman, allTransactions: allTransactions),
            StockScreen(salesman: widget.salesman),
            TransactionsScreen(salesman: widget.salesman, allTransactions: allTransactions),
            MTScreen(salesman: widget.salesman), // NEW: MT Screen
          ];

          return screens[_selectedIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'MT'), // Changed 'Finance' to 'MT'
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
