import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // For Bottom Navigation Bar, assuming Dashboard is index 0

  // Dummy data for KPIs
  final Map<String, dynamic> kpiData = {
    'Total Net Sales': {'value': 2390.00, 'color': Colors.deepPurple, 'icon': Icons.trending_up},
    'Payments Received': {'value': 2760.00, 'color': Colors.lightGreen, 'icon': Icons.payments},
    'Payment Cash in Hand/Bank': {'value': 1870.00, 'color': Colors.orange, 'icon': Icons.account_balance_wallet},
    'Outstanding Arrears': {'value': 520.00, 'color': Colors.redAccent, 'icon': Icons.warning},
  };

  // Dummy data for Recent Activity Feed
  final List<Map<String, String>> recentActivities = [
    {'type': 'Sale', 'description': 'Sale #1234 to Salesman A', 'amount': 'PKR 15,000', 'date': 'July 5'},
    {'type': 'Payment', 'description': 'Received from Salesman B', 'amount': 'PKR 8,000', 'date': 'July 4'},
    {'type': 'Stock Out', 'description': '50 packs Red Label to Salesman C', 'amount': '', 'date': 'July 4'},
    {'type': 'Expense', 'description': 'Car Maintenance', 'amount': 'PKR 2,500', 'date': 'July 3'},
    {'type': 'Sale', 'description': 'Sale #1235 to Salesman D', 'amount': 'PKR 12,000', 'date': 'July 3'},
    {'type': 'Payment', 'description': 'Paid to Factory Distributor', 'amount': 'PKR 50,000', 'date': 'July 2'},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // In a real app, you would navigate to different screens here
    // based on the index (e.g., Dashboard, Sales, Stock, Finance)
    // For now, we'll just update the selected index.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cigarette Management Agency',
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Open drawer
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
            // KPI Cards Section
            const Text(
              'Dashboard Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.2, // Adjust as needed for card height
              ),
              itemCount: kpiData.length,
              itemBuilder: (context, index) {
                String key = kpiData.keys.elementAt(index);
                Map<String, dynamic> data = kpiData[key]!;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: data['color'].withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          data['icon'],
                          color: Colors.white,
                          size: 30,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'PKR ${data['value'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
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

            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 2.0, // Wider buttons
              children: [
                _buildQuickActionButton(context, 'Add New Sale', Icons.add_shopping_cart, Colors.blue),
                _buildQuickActionButton(context, 'Receive Payment', Icons.payments, Colors.green),
                _buildQuickActionButton(context, 'Record Expense', Icons.receipt_long, Colors.orange),
                _buildQuickActionButton(context, 'Check Stock Levels', Icons.inventory, Colors.purple),
              ],
            ),
            const SizedBox(height: 30),

            // Recent Activity Feed
            const Text(
              'Recent Activity Feed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentActivities.length,
              itemBuilder: (context, index) {
                final activity = recentActivities[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _getActivityIcon(activity['type']!),
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['description']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                activity['date']!,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (activity['amount']!.isNotEmpty)
                          Text(
                            activity['amount']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
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
            label: 'Finance', // Represents payments/claims
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

  // Helper function to build quick action buttons
  Widget _buildQuickActionButton(BuildContext context, String title, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title pressed!')),
        );
        // In a real app, navigate to the respective module/form
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // Helper function to get activity icon based on type
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Sale':
        return Icons.shopping_bag;
      case 'Payment':
        return Icons.payments;
      case 'Stock Out':
        return Icons.outbox;
      case 'Expense':
        return Icons.money_off;
      default:
        return Icons.info_outline;
    }
  }
}