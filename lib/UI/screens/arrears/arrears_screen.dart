import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/arrear.dart'; // Import Arrear model
import 'package:cigarette_agency_management_app/models/salesman.dart'; // Import Salesman model for dropdown

class ArrearsScreen extends StatefulWidget {
  const ArrearsScreen({super.key});

  @override
  State<ArrearsScreen> createState() => _ArrearsScreenState();
}

class _ArrearsScreenState extends State<ArrearsScreen> {
  // Use a mutable list for arrears
  final List<Arrear> _arrears = List.from(Arrear.dummyArrears);

  // Filter state variables
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  Salesman? _selectedSalesmanFilter;
  String? _filterStatus; // 'All', 'Outstanding', 'Cleared'

  // Getter for filtered arrears
  List<Arrear> get _filteredArrears {
    return _arrears.where((arrear) {
      bool matchesDateRange = (_filterStartDate == null || arrear.dateIncurred.isAfter(_filterStartDate!.subtract(const Duration(days: 1)))) &&
          (_filterEndDate == null || arrear.dateIncurred.isBefore(_filterEndDate!.add(const Duration(days: 1))));
      bool matchesSalesman = _selectedSalesmanFilter == null || arrear.salesmanId == _selectedSalesmanFilter!.id;
      bool matchesStatus = _filterStatus == null || _filterStatus == 'All' || arrear.status == _filterStatus;
      return matchesDateRange && matchesSalesman && matchesStatus;
    }).toList();
  }

  // Getter for total outstanding amount
  double get _totalOutstandingAmount {
    return _arrears.where((arrear) => arrear.status == 'Outstanding').fold(0.0, (sum, arrear) => sum + arrear.amount);
  }

  // Helper to show options for an Arrear
  void _showArrearOptions(BuildContext context, Arrear arrear) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Arrear'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  _showAddEditArrearDialog(arrearToEdit: arrear); // Navigate to edit
                },
              ),
              if (arrear.status == 'Outstanding') // Only show "Mark as Collected" if outstanding
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Mark as Collected'),
                  onTap: () {
                    Navigator.pop(bc); // Close bottom sheet
                    _showMarkAsCollectedDialog(arrear);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Arrear'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  _confirmDeleteArrear(arrear); // Confirm before deleting
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Confirm Delete Dialog
  void _confirmDeleteArrear(Arrear arrear) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this arrear (PKR ${arrear.amount.toStringAsFixed(2)})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                setState(() {
                  _arrears.removeWhere((a) => a.id == arrear.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Arrear deleted!')),
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

  // Mark as Collected Dialog
  Future<void> _showMarkAsCollectedDialog(Arrear arrear) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController descriptionController = TextEditingController(text: arrear.clearanceDescription);
    DateTime? collectionDate = arrear.clearanceDate ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Mark Arrear as Collected'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mark this arrear as Collected:\n"${arrear.description}"'),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Collection Description (Optional)',
                          hintText: 'e.g., Collected by cash from shop manager',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(collectionDate!)),
                        decoration: const InputDecoration(
                          labelText: 'Collection Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: collectionDate!,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setStateInDialog(() { collectionDate = picked; });
                          }
                        },
                        validator: (value) => value!.isEmpty ? 'Select collection date' : null,
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
                        final index = _arrears.indexWhere((a) => a.id == arrear.id);
                        if (index != -1) {
                          _arrears[index] = arrear.copyWith(
                            status: 'Cleared',
                            clearanceDate: collectionDate,
                            clearanceDescription: descriptionController.text.isEmpty ? null : descriptionController.text,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Arrear for "${arrear.salesmanName}" marked as Collected!')),
                      );
                    }
                  },
                  child: const Text('Mark as Collected'),
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

  // Add/Edit Arrear Dialog
  Future<void> _showAddEditArrearDialog({Arrear? arrearToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final isEditing = arrearToEdit != null;

    Salesman? selectedSalesman = isEditing ? Salesman.dummySalesmen.firstWhere((s) => s.id == arrearToEdit!.salesmanId) : null;
    final TextEditingController amountController = TextEditingController(text: arrearToEdit?.amount.toString());
    final TextEditingController descriptionController = TextEditingController(text: arrearToEdit?.description);
    DateTime? dateIncurred = arrearToEdit?.dateIncurred ?? DateTime.now();

    final Arrear? result = await showDialog<Arrear>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Arrear' : 'Add New Arrear'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Salesman>(
                        decoration: const InputDecoration(labelText: 'Select Salesman', border: OutlineInputBorder()),
                        value: selectedSalesman,
                        items: Salesman.dummySalesmen.map((salesman) {
                          return DropdownMenuItem<Salesman>(value: salesman, child: Text(salesman.name));
                        }).toList(),
                        onChanged: isEditing ? null : (value) { setStateInDialog(() { selectedSalesman = value; }); }, // Disabled if editing
                        validator: (value) => value == null ? 'Select a salesman' : null,
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
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(dateIncurred!)),
                        decoration: const InputDecoration(labelText: 'Date Incurred', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(context: context, initialDate: dateIncurred!, firstDate: DateTime(2000), lastDate: DateTime(2101));
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
                      final newArrear = Arrear(
                        id: isEditing ? arrearToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        salesmanId: selectedSalesman!.id,
                        salesmanName: selectedSalesman!.name,
                        dateIncurred: dateIncurred!,
                        amount: double.parse(amountController.text),
                        description: descriptionController.text,
                        status: isEditing ? arrearToEdit!.status : 'Outstanding',
                        clearanceDate: isEditing ? arrearToEdit!.clearanceDate : null,
                        clearanceDescription: isEditing ? arrearToEdit!.clearanceDescription : null,
                      );
                      Navigator.of(dialogContext).pop(newArrear);
                    }
                  },
                  child: Text(isEditing ? 'Update Arrear' : 'Add Arrear'),
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
          final index = _arrears.indexWhere((a) => a.id == result.id);
          if (index != -1) _arrears[index] = result;
        } else {
          _arrears.insert(0, result);
        }
        _arrears.sort((a, b) => b.dateIncurred.compareTo(a.dateIncurred));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arrear ${isEditing ? 'updated' : 'added'}!')));
    }
    descriptionController.dispose(); amountController.dispose();
  }

  // Generate Report Method
  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report for ${_filteredArrears.length} arrears... (Placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define a reduced contentPadding for InputDecoration
    const EdgeInsetsGeometry reducedContentPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrears'),
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
            // Total Outstanding Amount KPI
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              color: Colors.red[100], // Light red for outstanding
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Outstanding Arrears:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900]),
                    ),
                    Text(
                      'PKR ${_totalOutstandingAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[900]),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Options
            const Text(
              'Filter Arrears',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Reduced spacing
            DropdownButtonFormField<Salesman>(
              decoration: InputDecoration( // Apply reduced padding
                labelText: 'Filter by Salesman', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.person_search, size: 20),
                contentPadding: reducedContentPadding,
              ),
              value: _selectedSalesmanFilter,
              items: Salesman.dummySalesmen.map((salesman) { // Assuming Salesman.dummySalesmen exists
                return DropdownMenuItem<Salesman>(value: salesman, child: Text(salesman.name));
              }).toList(),
              onChanged: (value) { setState(() { _selectedSalesmanFilter = value; }); },
              hint: const Text('All Salesmen'),
            ),
            const SizedBox(height: 10), // Reduced spacing
            DropdownButtonFormField<String>(
              decoration: InputDecoration( // Apply reduced padding
                labelText: 'Filter by Status', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.info_outline, size: 20),
                contentPadding: reducedContentPadding,
              ),
              value: _filterStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'Outstanding', child: Text('Outstanding')),
                DropdownMenuItem(value: 'Cleared', child: Text('Cleared')),
              ],
              onChanged: (value) { setState(() { _filterStatus = value; }); },
            ),
            const SizedBox(height: 10), // Reduced spacing
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: _filterStartDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterStartDate!)),
                    decoration: InputDecoration( // Apply reduced padding
                      labelText: 'From Date', border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      contentPadding: reducedContentPadding,
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: _filterStartDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                      if (picked != null) { setState(() { _filterStartDate = picked; }); }
                    },
                  ),
                ),
                const SizedBox(width: 8), // Reduced spacing
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: _filterEndDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterEndDate!)),
                    decoration: InputDecoration( // Apply reduced padding
                      labelText: 'To Date', border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      contentPadding: reducedContentPadding,
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: _filterEndDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                      if (picked != null) { setState(() { _filterEndDate = picked; }); }
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () { setState(() { _filterStartDate = null; _filterEndDate = null; _selectedSalesmanFilter = null; _filterStatus = null; }); },
                icon: const Icon(Icons.clear_all, size: 20), // Reduced icon size
                label: const Text('Clear Filters', style: TextStyle(fontSize: 12)), // Reduced text size
                style: TextButton.styleFrom(padding: EdgeInsets.zero), // Remove default padding
              ),
            ),
            const SizedBox(height: 15), // Reduced spacing

            _filteredArrears.isEmpty
                ? Center(
              child: Text(
                'No arrears to display for this period.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : Expanded( // Wrap ListView.builder in Expanded to fill available space
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling
                itemCount: _filteredArrears.length,
                itemBuilder: (context, index) {
                  final arrear = _filteredArrears[index];
                  Color statusColor;
                  TextDecoration? textDecoration;
                  if (arrear.status == 'Cleared') {
                    statusColor = Colors.green;
                    textDecoration = TextDecoration.lineThrough;
                  } else { // Outstanding
                    statusColor = Colors.orange;
                    textDecoration = null;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0), // Reduced list tile padding
                      title: Text(
                        'PKR ${arrear.amount.toStringAsFixed(2)} - ${arrear.salesmanName}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15, // Reduced font size
                          decoration: textDecoration,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            arrear.description,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700], decoration: textDecoration), // Reduced font size
                          ),
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(arrear.dateIncurred)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 6), // Reduced spacing
                          Row(
                            children: [
                              Chip(
                                label: Text(arrear.status, style: const TextStyle(color: Colors.white, fontSize: 10)), // Reduced chip font size
                                backgroundColor: statusColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink chip size
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              ),
                              if (arrear.status == 'Cleared' && arrear.clearanceDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0), // Reduced padding
                                  child: Text(
                                    'Collected on: ${DateFormat('yyyy-MM-dd').format(arrear.clearanceDate!)}',
                                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[600]), // Reduced font size
                                  ),
                                ),
                            ],
                          ),
                          if (arrear.status == 'Cleared' && arrear.clearanceDescription != null && arrear.clearanceDescription!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0), // Reduced padding
                              child: Text(
                                'Note: ${arrear.clearanceDescription!}',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[500]), // Reduced font size
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, size: 20), // Reduced icon size
                        onPressed: () => _showArrearOptions(context, arrear),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15), // Reduced spacing
            // Generate Report Button
            SizedBox(
              width: double.infinity,
              height: 40, // Reduced height
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.download, size: 20), // Reduced icon size
                label: const Text('Generate Report (Excel/PDF)', style: TextStyle(fontSize: 14)), // Reduced text size
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Reduced border radius
                  padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditArrearDialog(),
        icon: const Icon(Icons.add, size: 20), // Reduced icon size
        label: const Text('Add Arrear', style: TextStyle(fontSize: 14)), // Reduced text size
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        heroTag: 'addArrearFab', // Add a unique heroTag if multiple FABs are present
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}