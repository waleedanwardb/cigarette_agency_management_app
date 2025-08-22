import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/company_claim.dart'; // Import CompanyClaim model and globalClaims list

class CompanyClaimsScreen extends StatefulWidget {
  const CompanyClaimsScreen({super.key});

  @override
  State<CompanyClaimsScreen> createState() => _CompanyClaimsScreenState();
}

class _CompanyClaimsScreenState extends State<CompanyClaimsScreen> {
  int _selectedIndex = 3; // Assuming Finance is the 4th item (index 3) in bottom nav

  // Using the globalCompanyClaims list directly
  List<CompanyClaim> _claims = globalCompanyClaims;

  @override
  void initState() {
    super.initState();
    // Sort claims by date (most recent first) or status for consistent display
    _claims.sort((a, b) => b.dateIncurred.compareTo(a.dateIncurred));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Implement navigation for bottom nav if this screen is directly on it
  }

  // --- Helper to show options for a Company Claim ---
  void _showClaimOptions(BuildContext context, CompanyClaim claim) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Claim'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit Claim "${claim.description}" functionality!')),
                  );
                  // Implement edit claim functionality (e.g., show a pre-filled form)
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Claim'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  _confirmDeleteClaim(claim); // Confirm before deleting
                },
              ),
              if (claim.status != 'Paid') // Only show "Clear Claim" if not already paid
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Clear Claim (Mark as Paid)'),
                  onTap: () {
                    Navigator.pop(bc); // Close bottom sheet
                    _showClearClaimDialog(claim); // Show dialog to clear claim
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- Confirm Delete Claim Dialog ---
  void _confirmDeleteClaim(CompanyClaim claim) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this claim?\n"${claim.description}"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                setState(() {
                  _claims.removeWhere((c) => c.id == claim.id);
                  // Also remove from global list to keep state consistent
                  globalCompanyClaims.removeWhere((c) => c.id == claim.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Claim deleted successfully!')),
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

  // --- Clear Claim Dialog (Mark as Paid) ---
  Future<void> _showClearClaimDialog(CompanyClaim claim) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController descriptionController = TextEditingController(text: claim.clearanceDescription);
    DateTime? clearanceDate = claim.clearanceDate ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Clear Claim'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mark this claim as Paid:'),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Clearance Description (Optional)',
                          hintText: 'e.g., Cleared by audit on...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(clearanceDate!)),
                        decoration: const InputDecoration(
                          labelText: 'Clearance Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: clearanceDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setStateInDialog(() {
                              clearanceDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Mark as Paid'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      setState(() { // Update the main screen's state
                        final index = _claims.indexWhere((c) => c.id == claim.id);
                        if (index != -1) {
                          // Use copyWith to create a new instance with updated status
                          _claims[index] = claim.copyWith(
                            status: 'Paid',
                            clearanceDate: clearanceDate,
                            clearanceDescription: descriptionController.text.isEmpty ? null : descriptionController.text,
                          );
                        }
                        // Ensure the global list is also updated
                        final globalIndex = globalCompanyClaims.indexWhere((c) => c.id == claim.id);
                        if(globalIndex != -1){
                          globalCompanyClaims[globalIndex].markAsCleared(date: clearanceDate!, description: descriptionController.text);
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Claim "${claim.description}" marked as Paid!')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      descriptionController.dispose();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Company Claims',
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
        child: _claims.isEmpty
            ? Center(
          child: Text(
            'No company claims to display.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        )
            : ListView.builder(
          itemCount: _claims.length,
          itemBuilder: (context, index) {
            final claim = _claims[index];
            bool isPaid = claim.status == 'Paid';
            Color statusColor;
            if (isPaid) {
              statusColor = Colors.blue;
            } else {
              statusColor = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
                            claim.type,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isPaid ? TextDecoration.lineThrough : null, // Strikethrough
                            ),
                          ),
                        ),
                        Text(
                          'PKR ${claim.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            decoration: isPaid ? TextDecoration.lineThrough : null, // Strikethrough
                          ),
                        ),
                        IconButton( // Kebab menu for options
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showClaimOptions(context, claim),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      claim.description, // Full detailed description
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        decoration: isPaid ? TextDecoration.lineThrough : null, // Strikethrough
                      ),
                    ),
                    if (claim.brandName != null || claim.productName != null || claim.companyName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (claim.companyName != null)
                              Text('Company: ${claim.companyName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (claim.brandName != null)
                              Text('Brand: ${claim.brandName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (claim.productName != null)
                              Text('Product: ${claim.productName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (claim.schemeNames != null && claim.schemeNames!.isNotEmpty)
                              Text('Schemes: ${claim.schemeNames!.join(', ')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (claim.packsAffected != null)
                              Text('Packs: ${claim.packsAffected!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(isPaid ? Icons.check_circle : Icons.hourglass_empty, size: 18, color: statusColor),
                            const SizedBox(width: 8),
                            Text(
                              claim.status,
                              style: TextStyle(fontSize: 14, color: statusColor),
                            ),
                          ],
                        ),
                        Text(
                          'Incurred: ${DateFormat('yyyy-MM-dd').format(claim.dateIncurred)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    if (isPaid && claim.clearanceDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cleared on: ${DateFormat('yyyy-MM-dd').format(claim.clearanceDate!)}',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                            ),
                            if (claim.clearanceDescription != null && claim.clearanceDescription!.isNotEmpty)
                              Text(
                                'Reason: ${claim.clearanceDescription!}',
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add New Claim form goes here!')),
          );
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditClaimScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Claim'),
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
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}