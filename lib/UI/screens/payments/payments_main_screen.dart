// lib/UI/screens/payments/payments_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cigarette_agency_management_app/UI/screens/payments/distributor_payments_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/salesman_payments_screen.dart';

import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/services/payment_service.dart';
import 'package:cigarette_agency_management_app/models/payment.dart';

class PaymentsMainScreen extends StatefulWidget {
  const PaymentsMainScreen({super.key});

  @override
  State<PaymentsMainScreen> createState() => _PaymentsMainScreenState();
}

class _PaymentsMainScreenState extends State<PaymentsMainScreen> {
  int _selectedIndex = 3;

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

  void _navigateToCompanyPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DistributorPaymentsScreen()),
    );
  }

  void _navigateToSalesmanPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesmanPaymentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentService = Provider.of<PaymentService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payments',
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
        child: StreamBuilder<List<Payment>>(
          stream: paymentService.getPayments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final payments = snapshot.data ?? [];
            final double totalPaymentsMade = payments
                .where((p) => p.type == 'Company Payment' || p.type == 'Salesman Payment')
                .fold(0.0, (sum, item) => sum + item.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.payments, size: 30, color: Colors.blueAccent),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Payments Made This Month',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              Text(
                                'PKR ${totalPaymentsMade.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Includes all outgoing payments',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Payment Options',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToCompanyPayments,
                        icon: const Icon(Icons.business_center),
                        label: const Text('Payments to Company'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToSalesmanPayments,
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Payments to Salesmen'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Finance'),
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