import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/temporary_claim.dart'; // Import the TemporaryClaim model

// NEW IMPORTS for BottomNavigationBar navigation
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';


class TemporaryClaimsScreen extends StatefulWidget {
  const TemporaryClaimsScreen({super.key});

  @override
  State<TemporaryClaimsScreen> createState() => _TemporaryClaimsScreenState();
}

class _TemporaryClaimsScreenState extends State<TemporaryClaimsScreen> {
  // Use a mutable list for claims as they will be added/edited/deleted
  final List<TemporaryClaim> _claims = List.from(TemporaryClaim.dummyTemporaryClaims);

  // For Bottom Navigation Bar (assuming default tab is not this screen)
  int _selectedIndex = 0; // Temporary index, adjust based on your main navigation logic

  // --- NEW: Filter state variables ---
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterStatus; // 'All', 'Pending', 'Cleared'

  // --- NEW: Getter for filtered claims ---
  List<TemporaryClaim> get _filteredClaims {
    return _claims.where((claim) {
      final claimDate = claim.dateIncurred;
      bool matchesDateRange = (_filterStartDate == null || claimDate.isAfter(_filterStartDate!.subtract(const Duration(days: 1)))) &&
          (_filterEndDate == null || claimDate.isBefore(_filterEndDate!.add(const Duration(days: 1))));
      bool matchesStatus = _filterStatus == null || _filterStatus == 'All' || claim.status == _filterStatus;
      return matchesDateRange && matchesStatus;
    }).toList();
  }

  // Helper to show options for a Temporary Claim
  void _showClaimOptions(BuildContext context, TemporaryClaim claim) {
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
                  _showAddEditClaimDialog(claimToEdit: claim); // Navigate to edit
                },
              ),
              if (claim.status == 'Pending') // Only show "Mark as Cleared" if pending
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Mark as Cleared'),
                  onTap: () {
                    Navigator.pop(bc); // Close bottom sheet
                    _showMarkAsClearedDialog(claim);
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
            ],
          ),
        );
      },
    );
  }

  // Confirm Delete Dialog
  void _confirmDeleteClaim(TemporaryClaim claim) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this temporary claim?\n"${claim.description}"'),
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
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Claim "${claim.description}" deleted!')),
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

  // Mark as Cleared Dialog
  Future<void> _showMarkAsClearedDialog(TemporaryClaim claim) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController descriptionController = TextEditingController(text: claim.clearanceDescription);
    DateTime? clearanceDate = claim.clearanceDate ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Mark Claim as Cleared'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mark this claim as Cleared: "${claim.description}"'),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Clearance Description (Optional)',
                          hintText: 'e.g., Approved by Manager on...',
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
                            initialDate: clearanceDate!,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setStateInDialog(() { clearanceDate = picked; });
                          }
                        },
                        validator: (value) => value!.isEmpty ? 'Select clearance date' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop();
                      setState(() {
                        final index = _claims.indexWhere((c) => c.id == claim.id);
                        if (index != -1) {
                          _claims[index] = claim.copyWith(
                            status: 'Cleared',
                            clearanceDate: clearanceDate,
                            clearanceDescription: descriptionController.text.isEmpty ? null : descriptionController.text,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Claim "${claim.description}" marked as Cleared!')),
                      );
                    }
                  },
                  child: const Text('Mark as Cleared'),
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

  // Add/Edit Claim Dialog/Screen
  Future<void> _showAddEditClaimDialog({TemporaryClaim? claimToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final isEditing = claimToEdit != null;

    final TextEditingController descriptionController = TextEditingController(text: claimToEdit?.description);
    final TextEditingController amountController = TextEditingController(text: claimToEdit?.amount.toString());
    DateTime? dateIncurred = claimToEdit?.dateIncurred ?? DateTime.now();

    final TemporaryClaim? result = await showDialog<TemporaryClaim>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Temporary Claim' : 'Add New Temporary Claim'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount (PKR)', border: OutlineInputBorder()),
                        validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0) ? 'Enter valid amount' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(dateIncurred!)),
                        decoration: const InputDecoration(labelText: 'Date Incurred', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context, initialDate: dateIncurred!, firstDate: DateTime(2000), lastDate: DateTime(2101),
                          );
                          if (picked != null) { setStateInDialog(() { dateIncurred = picked; }); }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newClaim = TemporaryClaim(
                        id: isEditing ? claimToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        description: descriptionController.text,
                        amount: double.parse(amountController.text),
                        status: isEditing ? claimToEdit!.status : 'Pending',
                        dateIncurred: dateIncurred!,
                        clearanceDate: isEditing ? claimToEdit!.clearanceDate : null,
                        clearanceDescription: isEditing ? claimToEdit!.clearanceDescription : null,
                      );
                      Navigator.of(dialogContext).pop(newClaim);
                    }
                  },
                  child: Text(isEditing ? 'Update Claim' : 'Add Claim'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isEditing) {
          final index = _claims.indexWhere((c) => c.id == result.id);
          if (index != -1) _claims[index] = result;
        } else {
          _claims.insert(0, result);
        }
        _claims.sort((a, b) => b.dateIncurred.compareTo(a.dateIncurred));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim ${isEditing ? 'updated' : 'added'}!')));
    }
    descriptionController.dispose();
    amountController.dispose();
  }

  // --- NEW: Generate Report Button ---
  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report for ${_filteredClaims.length} temporary claims... (Placeholder)')),
    );
    // In a real app, this would use the _filteredClaims list to create an Excel/PDF report.
  }

  // Handle Bottom Navigation Bar taps
  final List<Widget> _bottomNavScreens = const [
    HomeScreen(),
    DashboardScreen(),
    StockMainScreen(),
    PaymentsMainScreen(),
  ];

  void _onBottomNavItemTapped(int index) {
    // This handles the navigation for the BottomNavigationBar
    // Only navigate if different tab is selected.
    // For this specific screen, we don't have a direct index in the main nav,
    // so we'll just simulate changing selected state or navigate to a main hub.
    // In your AppDrawer, it navigates directly to this screen.
    // If you want this screen to also be a main tab, you'd add it to _bottomNavScreens and manage its index.
    // For now, let's keep the _selectedIndex for visual feedback only.
    setState(() {
      _selectedIndex = index;
    });
    // Example: Navigate to Finance tab if this screen is considered part of it
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaymentsMainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporary Claims'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () { /* Navigate to profile */ }),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NEW: Filter Options ---
            const Text(
              'Filter Claims',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: _filterStartDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterStartDate!)),
                    decoration: const InputDecoration(labelText: 'From Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: _filterStartDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                      if (picked != null) { setState(() { _filterStartDate = picked; }); }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: _filterEndDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterEndDate!)),
                    decoration: const InputDecoration(labelText: 'To Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: _filterEndDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                      if (picked != null) { setState(() { _filterEndDate = picked; }); }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Filter by Status', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info_outline)),
              value: _filterStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Cleared', child: Text('Cleared')),
              ],
              onChanged: (value) { setState(() { _filterStatus = value; }); },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () { setState(() { _filterStartDate = null; _filterEndDate = null; _filterStatus = null; }); },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ),
            const SizedBox(height: 20),

            _filteredClaims.isEmpty
                ? Center(
              child: Text(
                'No temporary claims to display for this period.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : Expanded( // Wrap ListView.builder in Expanded to fill available space
              child: ListView.builder(
                shrinkWrap: true, // ShrinkWrap is good, but Expanded is needed for vertical space
                physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling
                itemCount: _filteredClaims.length,
                itemBuilder: (context, index) {
                  final claim = _filteredClaims[index];
                  Color statusColor;
                  TextDecoration? textDecoration;
                  if (claim.status == 'Cleared') {
                    statusColor = Colors.green;
                    textDecoration = TextDecoration.lineThrough;
                  } else if (claim.status == 'Pending') {
                    statusColor = Colors.orange;
                    textDecoration = null;
                  } else { // e.g., 'Rejected'
                    statusColor = Colors.red;
                    textDecoration = null;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        claim.description,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: textDecoration,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Amount: PKR ${claim.amount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700], decoration: textDecoration),
                          ),
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(claim.dateIncurred)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text(claim.status, style: const TextStyle(color: Colors.white)),
                                backgroundColor: statusColor,
                              ),
                              if (claim.status == 'Cleared' && claim.clearanceDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Cleared on: ${DateFormat('yyyy-MM-dd').format(claim.clearanceDate!)}',
                                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                                  ),
                                ),
                            ],
                          ),
                          if (claim.status == 'Cleared' && claim.clearanceDescription != null && claim.clearanceDescription!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Note: ${claim.clearanceDescription!}',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showClaimOptions(context, claim),
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped on claim: ${claim.description}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Generate Report Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.download),
                label: const Text('Generate Report (Excel/PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditClaimDialog(),
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
        // No explicit currentIndex for this screen as it's not a primary bottom nav tab.
        // It's usually navigated to from a drawer or other screen.
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // This handles the navigation for the BottomNavigationBar
          // Replace with your actual main navigation logic.
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StockMainScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsMainScreen()));
          }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}