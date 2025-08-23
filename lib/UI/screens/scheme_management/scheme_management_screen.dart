// lib/UI/screens/scheme_management/scheme_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import models and services
import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/services/scheme_service.dart';
import 'package:cigarette_agency_management_app/UI/screens/scheme_management/add_edit_scheme_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';


class SchemeManagementScreen extends StatefulWidget {
  const SchemeManagementScreen({super.key});

  @override
  State<SchemeManagementScreen> createState() => _SchemeManagementScreenState();
}

class _SchemeManagementScreenState extends State<SchemeManagementScreen> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showSchemeOptions(BuildContext context, Scheme scheme, SchemeService schemeService) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Scheme'),
                onTap: () {
                  Navigator.pop(bc);
                  _navigateToAddEditScheme(scheme: scheme);
                },
              ),
              ListTile(
                leading: Icon(scheme.isActive ? Icons.toggle_off : Icons.toggle_on),
                title: Text(scheme.isActive ? 'Deactivate Scheme' : 'Activate Scheme'),
                onTap: () async {
                  Navigator.pop(bc);
                  final updatedScheme = Scheme(
                    id: scheme.id,
                    name: scheme.name,
                    type: scheme.type,
                    amount: scheme.amount,
                    isActive: !scheme.isActive,
                    validFrom: scheme.validFrom,
                    validTo: scheme.validTo,
                    companyName: scheme.companyName,
                    productName: scheme.productName,
                    description: scheme.description,
                    applicableProducts: scheme.applicableProducts,
                  );
                  await schemeService.updateScheme(updatedScheme);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${scheme.name} is now ${updatedScheme.isActive ? 'Active' : 'Inactive'}!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Scheme'),
                onTap: () {
                  Navigator.pop(bc);
                  _confirmDeleteScheme(scheme, schemeService);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteScheme(Scheme scheme, SchemeService schemeService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete scheme "${scheme.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await schemeService.deleteScheme(scheme.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${scheme.name} deleted successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddEditScheme({Scheme? scheme}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSchemeScreen(scheme: scheme),
      ),
    );

    if (result != null && result is Scheme) {
      final schemeService = Provider.of<SchemeService>(context, listen: false);
      if (scheme == null) {
        await schemeService.addScheme(result);
      } else {
        await schemeService.updateScheme(result);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheme "${result.name}" ${scheme == null ? 'added' : 'updated'}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemeService = Provider.of<SchemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scheme Management',
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
      body: StreamBuilder<List<Scheme>>(
        stream: schemeService.getSchemes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No schemes available.\nTap "+" to add a new scheme.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          final schemes = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: schemes.length,
              itemBuilder: (context, index) {
                final scheme = schemes[index];
                Color statusColor = scheme.isActive ? Colors.green : Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () => _navigateToAddEditScheme(scheme: scheme),
                    onLongPress: () => _showSchemeOptions(context, scheme, schemeService),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  scheme.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  scheme.isActive ? 'Active' : 'Inactive',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.business, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Company: ${scheme.companyName}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.inventory_2, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Product: ${scheme.productName}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.discount, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Type: ${scheme.type} (PKR ${scheme.amount.toStringAsFixed(2)}/pack)',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Validity: ${DateFormat('MMM dd, yyyy').format(scheme.validFrom)} - ${DateFormat('MMM dd, yyyy').format(scheme.validTo)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditScheme(),
        icon: const Icon(Icons.add),
        label: const Text('Add New Scheme'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Finance'),
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