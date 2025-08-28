import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import all your screen files using the correct package name
import 'package:cigarette_agency_management_app/UI/screens/mt_management/mt_management_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart'; // Often needed for BottomNav
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_stock_list_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/scheme_management/scheme_management_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/company_claims/company_claims_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/personal_expenses/personal_expenses_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/claims/temporary_claims_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/arrears/arrears_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/lighter_stock_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/auth/login_screen.dart';

// You will also need to import your AuthService here if you haven't already
import 'package:cigarette_agency_management_app/services/auth_service.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer first
    Navigator.push( // Use push for drawer items to allow back navigation
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // New Logout method
  Future<void> _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    // The StreamBuilder in main.dart will handle navigation back to LoginScreen.
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Drawer Header
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF6A1B9A),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF6A1B9A)),
                ),
                SizedBox(height: 10),
                Text(
                  'Agency Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'admin@agency.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation ListTiles
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => _navigateToScreen(context, const DashboardScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home (Products)'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Salesman Management'),
            onTap: () => _navigateToScreen(context, const SalesmanStockListScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Stock Management'),
            onTap: () => _navigateToScreen(context, const StockMainScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('Scheme Management'),
            onTap: () => _navigateToScreen(context, const SchemeManagementScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Payments'),
            onTap: () => _navigateToScreen(context, const PaymentsMainScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Company Claims'),
            onTap: () => _navigateToScreen(context, const CompanyClaimsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Temporary Claims'),
            onTap: () => _navigateToScreen(context, const TemporaryClaimsScreen()),
          ),
          // REMOVED: Salesman Accounts (covered by Salesman Management)
          ListTile(
            leading: const Icon(Icons.money_off),
            title: const Text('Personal Expenses'),
            onTap: () => _navigateToScreen(context, const PersonalExpensesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Arrears'),
            onTap: () => _navigateToScreen(context, const ArrearsScreen()),
          ),
          // --- PLACEHOLDER: MT Management ---
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('MT Management'),
            onTap: () => _navigateToScreen(context, const MTManagementScreen()),
          ),
          // --- PLACEHOLDER: Lighter Stock ---
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Lighter Stock'),
            onTap: () => _navigateToScreen(context, const LighterStockScreen()),
          ),
          const Divider(),
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}