import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/mt_claim.dart'; // Import the MTClaim model

// Import main screen paths for BottomNavigationBar navigation
import 'package:cigarette_agency_management_app/UI/screens/home_screen/home_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';


class MTManagementScreen extends StatefulWidget {
  const MTManagementScreen({super.key});

  @override
  State<MTManagementScreen> createState() => _MTManagementScreenState();
}

class _MTManagementScreenState extends State<MTManagementScreen> {
  final List<MTClaim> _mtClaims = List.from(MTClaim.dummyMTClaims);

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterStatus;

  List<MTClaim> get _filteredMTClaims {
    return _mtClaims.where((claim) {
      bool matchesDateRange = (_filterStartDate == null || claim.dateClaimed.isAfter(_filterStartDate!.subtract(const Duration(days: 1)))) &&
          (_filterEndDate == null || claim.dateClaimed.isBefore(_filterEndDate!.add(const Duration(days: 1))));
      bool matchesStatus = _filterStatus == null || _filterStatus == 'All' || claim.status == _filterStatus;
      return matchesDateRange && matchesStatus;
    }).toList();
  }

  void _onItemTapped(int index) {
    // This is not a bottom nav screen, so this method is a placeholder
  }

  void _showClaimOptions(BuildContext context, MTClaim claim) {
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
                  Navigator.pop(bc);
                  _showAddEditClaimDialog(claimToEdit: claim);
                },
              ),
              if (claim.status == 'Pending Audit')
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Mark as Cleared'),
                  onTap: () {
                    Navigator.pop(bc);
                    _showClearClaimDialog(claim);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Claim'),
                onTap: () {
                  Navigator.pop(bc);
                  _confirmDeleteClaim(claim);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteClaim(MTClaim claim) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this MT claim?\n"${claim.description}"'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() { _mtClaims.removeWhere((c) => c.id == claim.id); });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('MT claim deleted!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClearClaimDialog(MTClaim claim) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController notesController = TextEditingController(text: claim.auditorNotes);
    DateTime clearanceDate = claim.auditClearanceDate ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Clear MT Claim'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mark this claim as Cleared: "${claim.description}"'),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Auditor Notes (Optional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(clearanceDate)),
                        decoration: const InputDecoration(labelText: 'Clearance Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context, initialDate: clearanceDate, firstDate: DateTime(2000), lastDate: DateTime(2101),
                          );
                          if (picked != null) { setStateInDialog(() { clearanceDate = picked; }); }
                        },
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
                        final index = _mtClaims.indexWhere((c) => c.id == claim.id);
                        if (index != -1) {
                          _mtClaims[index] = claim.copyWith(
                            status: 'Cleared',
                            auditClearanceDate: clearanceDate,
                            auditorNotes: notesController.text.isEmpty ? null : notesController.text,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim "${claim.description}" marked as Cleared!')));
                    }
                  },
                  child: const Text('Mark as Cleared'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) { notesController.dispose(); });
  }

  Future<void> _showAddEditClaimDialog({MTClaim? claimToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final isEditing = claimToEdit != null;
    final TextEditingController descriptionController = TextEditingController(text: claimToEdit?.description);
    final TextEditingController quantityController = TextEditingController(text: claimToEdit?.quantity.toString());
    final TextEditingController valueController = TextEditingController(text: claimToEdit?.value.toString());
    String? selectedType = claimToEdit?.type;
    DateTime dateClaimed = claimToEdit?.dateClaimed ?? DateTime.now();

    final MTClaim? result = await showDialog<MTClaim>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit MT Claim' : 'Add New MT Claim'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Claim Type', border: OutlineInputBorder()),
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(value: 'Lighter Gift', child: Text('Lighter Gift')),
                          DropdownMenuItem(value: 'Empty Box Exchange', child: Text('Empty Box Exchange')),
                          DropdownMenuItem(value: 'Cash Gift', child: Text('Cash Gift')),
                        ],
                        onChanged: (value) { setStateInDialog(() { selectedType = value; }); },
                        validator: (value) => value == null ? 'Select a claim type' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity (e.g., Lighters)', border: OutlineInputBorder()),
                        validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0) ? 'Enter valid quantity' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Value (PKR)', border: OutlineInputBorder()),
                        validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) < 0) ? 'Enter valid value' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(dateClaimed)),
                        decoration: const InputDecoration(labelText: 'Date Claimed', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context, initialDate: dateClaimed, firstDate: DateTime(2000), lastDate: DateTime(2101),
                          );
                          if (picked != null) { setStateInDialog(() { dateClaimed = picked; }); }
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
                      final newClaim = MTClaim(
                        id: isEditing ? claimToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        type: selectedType!,
                        description: descriptionController.text,
                        quantity: double.parse(quantityController.text),
                        value: double.parse(valueController.text),
                        dateClaimed: dateClaimed,
                        status: isEditing ? claimToEdit!.status : 'Pending Audit',
                        auditClearanceDate: isEditing ? claimToEdit!.auditClearanceDate : null,
                        auditorNotes: isEditing ? claimToEdit!.auditorNotes : null,
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
          final index = _mtClaims.indexWhere((c) => c.id == result.id);
          if (index != -1) _mtClaims[index] = result;
        } else {
          _mtClaims.insert(0, result);
        }
        _mtClaims.sort((a, b) => b.dateClaimed.compareTo(a.dateClaimed));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('MT Claim ${isEditing ? 'updated' : 'added'}!')));
    }
    descriptionController.dispose();
    quantityController.dispose();
    valueController.dispose();
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report for ${_filteredMTClaims.length} MT claims... (Placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MT Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () { Navigator.of(context).pop(); },
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
            const Text('Filter MT Claims', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              decoration: const InputDecoration(labelText: 'Filter by Status', border: OutlineInputBorder()),
              value: _filterStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'Pending Audit', child: Text('Pending Audit')),
                DropdownMenuItem(value: 'Cleared', child: Text('Cleared')),
                DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
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

            _filteredMTClaims.isEmpty
                ? Center(
              child: Text(
                'No MT claims found for this period.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _filteredMTClaims.length,
                itemBuilder: (context, index) {
                  final claim = _filteredMTClaims[index];
                  Color statusColor;
                  TextDecoration? textDecoration;
                  if (claim.status == 'Cleared') {
                    statusColor = Colors.green;
                    textDecoration = TextDecoration.lineThrough;
                  } else if (claim.status == 'Pending Audit') {
                    statusColor = Colors.orange;
                    textDecoration = null;
                  } else {
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
                        '${claim.type} (PKR ${claim.value.toStringAsFixed(2)})',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: textDecoration),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(claim.description, style: TextStyle(fontSize: 14, color: Colors.grey[700], decoration: textDecoration)),
                          Text('Quantity: ${claim.quantity.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text('Date Claimed: ${DateFormat('yyyy-MM-dd').format(claim.dateClaimed)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          if (claim.status == 'Cleared' && claim.auditClearanceDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Cleared on: ${DateFormat('yyyy-MM-dd').format(claim.auditClearanceDate!)}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                            ),
                          if (claim.status == 'Cleared' && claim.auditorNotes != null && claim.auditorNotes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('Notes: ${claim.auditorNotes!}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showClaimOptions(context, claim),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
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