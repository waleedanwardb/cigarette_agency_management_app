import 'package:flutter/material.dart';

// Import the sub-screens for payments management
import 'package:cigarette_agency_management_app/UI/screens/payments/distributor_payments_screen.dart'; // This will serve as 'Payments to Company'
import 'package:cigarette_agency_management_app/UI/screens/payments/salesman_payments_screen.dart'; // This is 'Payments to Salesmen'

// Import main screen paths for BottomNavigationBar navigation
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';


// Dummy data model for Payment Summary KPI (unchanged)
class PaymentSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  PaymentSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class PaymentsMainScreen extends StatefulWidget {
  const PaymentsMainScreen({super.key});

  @override
  State<PaymentsMainScreen> createState() => _PaymentsMainScreenState();
}

class _PaymentsMainScreenState extends State<PaymentsMainScreen> {
  int _selectedIndex = 3; // Assuming Finance is the 4th item (index 3) in bottom nav

  final List<PaymentSummary> _paymentSummaries = [
    PaymentSummary(
      title: 'Total Payments Made This Month',
      value: 'PKR 1,500,000',
      subtitle: 'Includes all outgoing payments',
      icon: Icons.payments,
      color: Colors.blueAccent,
    ),
    PaymentSummary(
      title: 'Outstanding Company Payments', // Updated label
      value: 'PKR 250,000',
      subtitle: 'Pending payments to companies for stock',
      icon: Icons.warning,
      color: Colors.orange,
    ),
  ];

  // List of main screens for BottomNavigationBar navigation
  final List<Widget> _bottomNavScreens = const [
    HomeScreen(), // Index 0
    DashboardScreen(), // Index 1
    StockMainScreen(), // Index 2
    PaymentsMainScreen(), // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // This ensures bottom nav selection also navigates
    if (index != _selectedIndex) { // Only navigate if different tab is selected
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _bottomNavScreens[index]),
      );
    }
  }

  // Navigation to the screen managing payments TO COMPANY (Distributor Invoices)
  void _navigateToCompanyPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DistributorPaymentsScreen()), // Renamed conceptually
    );
  }

  // Navigation to the screen managing payments TO SALESMEN (Salary/Advances)
  void _navigateToSalesmanPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesmanPaymentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payments',
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Or menu icon if directly from login
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
              'Payment Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentSummaries.length,
              itemBuilder: (context, index) {
                final summary = _paymentSummaries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(summary.icon, size: 30, color: summary.color),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.title,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              Text(
                                summary.value,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                summary.subtitle,
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                    onPressed: _navigateToCompanyPayments, // Navigate to Company Payments
                    icon: const Icon(Icons.business_center), // Changed icon
                    label: const Text('Payments to Company'), // Updated label
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
                    onPressed: _navigateToSalesmanPayments, // Navigate to Salesman Payments
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