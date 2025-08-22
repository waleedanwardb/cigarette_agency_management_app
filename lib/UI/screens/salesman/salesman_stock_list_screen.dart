// lib/UI/screens/salesman/salesman_stock_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Import necessary files
import 'package:cigarette_agency_management_app/models/salesman.dart'; // Your Salesman model
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_stock_detail_screen.dart'; // Detail screen
import 'package:cigarette_agency_management_app/UI/screens/salesman/add_salesman_screen.dart'; // Add/Edit screen
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_accounts_screen.dart'; // NEW: Import SalesmanAccountsScreen
import 'package:cigarette_agency_management_app/services/salesman_service.dart'; // Import the service

// Import main screens for BottomNavigationBar navigation
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';


class SalesmanStockListScreen extends StatefulWidget {
  const SalesmanStockListScreen({super.key});

  @override
  State<SalesmanStockListScreen> createState() => _SalesmanStockListScreenState();
}

class _SalesmanStockListScreenState extends State<SalesmanStockListScreen> {
  int _selectedIndex = 2;

  // No need for a local dummy list anymore. Data will come from Firestore via a Stream.

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Navigation to Add/Edit Salesman Screen
  void _navigateToAddEditSalesmanScreen({Salesman? salesman}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSalesmanScreen(salesman: salesman), // Pass salesman for editing
      ),
    );

    // This part of the logic will now be handled by the services updating Firestore.
    // The StreamBuilder will automatically rebuild the UI.
    // So, we don't need to manually update a local list.
  }

  // Helper for Salesman Options (Edit/Freeze/Delete)
  void _showSalesmanOptions(BuildContext context, Salesman salesman) {
    // Get the service instance from the context
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  _navigateToAddEditSalesmanScreen(salesman: salesman); // Navigate to edit
                },
              ),
              ListTile(
                leading: Icon(salesman.isFrozen ? Icons.person_add_disabled : Icons.person_off),
                title: Text(salesman.isFrozen ? 'Unfreeze Salesman' : 'Freeze Salesman'),
                onTap: () async {
                  Navigator.pop(bc);
                  // Call the service to update the salesman's frozen status in Firestore
                  final updatedSalesman = salesman.copyWith(isFrozen: !salesman.isFrozen);
                  await salesmanService.updateSalesman(updatedSalesman);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${salesman.name} is now ${updatedSalesman.isFrozen ? 'Frozen' : 'Unfrozen'}!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Salesman'),
                onTap: () {
                  Navigator.pop(bc);
                  _confirmDeleteSalesman(salesman, salesmanService);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Confirm Delete Dialog
  void _confirmDeleteSalesman(Salesman salesman, SalesmanService salesmanService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete salesman "${salesman.name}"? This will remove all their records.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                // Call the service to delete the salesman from Firestore
                await salesmanService.deleteSalesman(salesman.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${salesman.name} deleted successfully!')),
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


  @override
  Widget build(BuildContext context) {
    // Get the service instance from the context
    final salesmanService = Provider.of<SalesmanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Salesman Management', // Updated title
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Salesman...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // --- Use StreamBuilder to listen to Firestore changes ---
          Expanded(
            child: StreamBuilder<List<Salesman>>(
              stream: salesmanService.getSalesmen(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint(snapshot.error.toString());
                  return Center(child: Text('Error fetching data: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No salesmen added yet.\nTap "+" to add a new salesman.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }

                final salesmen = snapshot.data!;
                return ListView.builder(
                  itemCount: salesmen.length,
                  itemBuilder: (context, index) {
                    final salesman = salesmen[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: salesman.isFrozen ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          // FIX: Navigate to the new SalesmanAccountsScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalesmanAccountsScreen(salesman: salesman),
                            ),
                          );
                        },
                        onLongPress: () => _showSalesmanOptions(context, salesman),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(salesman.imageUrl),
                                backgroundColor: Colors.grey[200],
                                child: salesman.imageUrl.isEmpty
                                    ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      salesman.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        decoration: salesman.isFrozen ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${salesman.idCardNumber}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    Text(
                                      'Status: ${salesman.isFrozen ? 'Frozen' : 'Active'}',
                                      style: TextStyle(fontSize: 12, color: salesman.isFrozen ? Colors.red : Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditSalesmanScreen(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Salesman'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}