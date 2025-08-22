// lib/UI/screens/scheme_management/scheme_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/scheme.dart';
import 'package:cigarette_agency_management_app/UI/screens/scheme_management/add_edit_scheme_screen.dart';


class SchemeManagementScreen extends StatefulWidget {
  const SchemeManagementScreen({super.key});

  @override
  State<SchemeManagementScreen> createState() => _SchemeManagementScreenState();
}

class _SchemeManagementScreenState extends State<SchemeManagementScreen> {
  int _selectedIndex = 3;

  final List<Scheme> _schemes = List.from(Scheme.dummySchemes);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper to show options for a Scheme (Edit/Activate/Deactivate/Delete)
  void _showSchemeOptions(BuildContext context, Scheme scheme) {
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
                onTap: () {
                  Navigator.pop(bc);
                  setState(() {
                    final index = _schemes.indexWhere((s) => s.id == scheme.id);
                    if (index != -1) {
                      _schemes[index] = Scheme(
                        id: scheme.id,
                        name: scheme.name,
                        type: scheme.type,
                        amount: scheme.amount,
                        isActive: !scheme.isActive, // Toggle status
                        validFrom: scheme.validFrom,
                        validTo: scheme.validTo,
                        companyName: scheme.companyName, // Include new field
                        productName: scheme.productName, // Include new field
                        description: scheme.description,
                        applicableProducts: scheme.applicableProducts,
                      );
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${scheme.name} is now ${scheme.isActive ? 'Inactive' : 'Active'}!')), // Message reflects old state, will update on rebuild
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Scheme'),
                onTap: () {
                  Navigator.pop(bc);
                  _confirmDeleteScheme(scheme);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Confirm Delete Dialog
  void _confirmDeleteScheme(Scheme scheme) {
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _schemes.removeWhere((s) => s.id == scheme.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${scheme.name} deleted successfully! (Simulated)')),
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

  // Navigation to Add/Edit Scheme Screen
  void _navigateToAddEditScheme({Scheme? scheme}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSchemeScreen(scheme: scheme),
      ),
    );

    if (result != null && result is Scheme) {
      setState(() {
        if (scheme == null) {
          _schemes.add(result);
        } else {
          final index = _schemes.indexWhere((s) => s.id == result.id);
          if (index != -1) {
            _schemes[index] = result;
          }
        }
        _schemes.sort((a, b) => a.name.compareTo(b.name));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheme "${result.name}" ${scheme == null ? 'added' : 'updated'}!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _schemes.isEmpty
            ? Center(
          child: Text(
            'No schemes available.\nTap "+" to add a new scheme.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        )
            : ListView.builder(
          itemCount: _schemes.length,
          itemBuilder: (context, index) {
            final scheme = _schemes[index];
            Color statusColor;
            if (scheme.isActive) {
              statusColor = Colors.green;
            } else {
              statusColor = Colors.red;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell( // Use InkWell for tap feedback
                onTap: () => _navigateToAddEditScheme(scheme: scheme), // Tap to edit
                onLongPress: () => _showSchemeOptions(context, scheme), // Long press for options
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
                          Icon(Icons.business, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Company: ${scheme.companyName}', // Display Company
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.inventory_2, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Product: ${scheme.productName}', // Display Product Name
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.discount, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Type: ${scheme.type} (PKR ${scheme.amount.toStringAsFixed(2)}/pack)',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Validity: ${DateFormat('MMM dd, yyyy').format(scheme.validFrom)} - ${DateFormat('MMM dd, yyyy').format(scheme.validTo)}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Description: ${scheme.description}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applies to: ${scheme.applicableProducts}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditScheme(), // Call without a scheme to add new
        icon: const Icon(Icons.add),
        label: const Text('Add New Scheme'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            label: 'Finance',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() { _selectedIndex = index; });
          // Example of actual navigation (assuming main tabs are handled in main.dart or a wrapper)
          // if (index != _selectedIndex) {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(builder: (context) => [
          //       const HomeScreen(),
          //       const DashboardScreen(),
          //       const StockMainScreen(),
          //       const PaymentsMainScreen()
          //     ][index]),
          //   );
          // }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}