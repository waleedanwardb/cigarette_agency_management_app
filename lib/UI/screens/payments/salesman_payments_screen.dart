import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import models
import 'package:cigarette_agency_management_app/models/salesman.dart'; // Import Salesman model
// If SalesmanPayment is in its own file, import it here:
// import 'package:cigarette_agency_management_app/models/salesman_payment.dart';


// Define SalesmanPayment model (if not already in lib/models/salesman_payment.dart)
// It's best to move this to lib/models/salesman_payment.dart and then import it here.
class SalesmanPayment {
  final String id;
  final String salesmanId;
  final String salesmanName;
  final DateTime date;
  final double amount;
  final String type; // 'Salary', 'Advance'
  final String description; // Optional: e.g., 'July Salary', 'Emergency Advance'

  SalesmanPayment({
    required this.id,
    required this.salesmanId,
    required this.salesmanName,
    required this.date,
    required this.amount,
    required this.type,
    this.description = '',
  });

  // Helper to create a copy with updated values (for immutable state management)
  SalesmanPayment copyWith({
    String? id,
    String? salesmanId,
    String? salesmanName,
    DateTime? date,
    double? amount,
    String? type,
    String? description,
  }) {
    return SalesmanPayment(
      id: id ?? this.id,
      salesmanId: salesmanId ?? this.salesmanId,
      salesmanName: salesmanName ?? this.salesmanName,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }
}


class SalesmanPaymentsScreen extends StatefulWidget {
  const SalesmanPaymentsScreen({super.key});

  @override
  State<SalesmanPaymentsScreen> createState() => _SalesmanPaymentsScreenState();
}

class _SalesmanPaymentsScreenState extends State<SalesmanPaymentsScreen> {
  // Dummy Payments to Salesman (this list will be filtered per salesman)
  // In a real app, you'd fetch this from a backend.
  final List<SalesmanPayment> _allSalesmanPayments = [
    SalesmanPayment(
        id: 'sp001', salesmanId: 's001', salesmanName: 'Ahmed Khan', date: DateTime(2025, 7, 25), amount: 35000.0, type: 'Salary', description: 'July 2025 Salary'),
    SalesmanPayment(
        id: 'sp002', salesmanId: 's002', salesmanName: 'Sara Ali', date: DateTime(2025, 7, 10), amount: 5000.0, type: 'Advance', description: 'Emergency Medical Advance'),
    SalesmanPayment(
        id: 'sp003', salesmanId: 's001', salesmanName: 'Ahmed Khan', date: DateTime(2025, 6, 25), amount: 35000.0, type: 'Salary', description: 'June 2025 Salary'),
    SalesmanPayment(
        id: 'sp004', salesmanId: 's003', salesmanName: 'Usman Tariq', date: DateTime(2025, 6, 5), amount: 2000.0, type: 'Advance', description: 'Travel Advance'),
    SalesmanPayment(
        id: 'sp005', salesmanId: 's001', salesmanName: 'Ahmed Khan', date: DateTime(2025, 7, 1), amount: 10000.0, type: 'Advance', description: 'Stock Purchase Advance'),
  ];

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  Salesman? _selectedSalesmanFilter;

  List<SalesmanPayment> get _filteredPayments {
    return _allSalesmanPayments.where((payment) {
      bool matchesDateRange = (_filterStartDate == null || payment.date.isAfter(_filterStartDate!.subtract(const Duration(days: 1)))) &&
          (_filterEndDate == null || payment.date.isBefore(_filterEndDate!.add(const Duration(days: 1))));
      bool matchesSalesman = _selectedSalesmanFilter == null || payment.salesmanId == _selectedSalesmanFilter!.id;
      return matchesDateRange && matchesSalesman;
    }).toList();
  }

  void _recordNewPayment() {
    _showAddEditPaymentDialog();
  }

  Future<void> _showAddEditPaymentDialog({SalesmanPayment? paymentToEdit}) async {
    final formKey = GlobalKey<FormState>(); // FIX: Renamed _formKey to formKey
    final isEditing = paymentToEdit != null;

    Salesman? dialogSelectedSalesman = isEditing ? Salesman.dummySalesmen.firstWhere((s) => s.id == paymentToEdit!.salesmanId) : null;
    final TextEditingController amountController = TextEditingController(text: paymentToEdit?.amount.toString());
    String? selectedType = paymentToEdit?.type;
    final TextEditingController descriptionController = TextEditingController(text: paymentToEdit?.description);
    DateTime selectedDate = paymentToEdit?.date ?? DateTime.now(); // FIX: Removed '?' and initialized to non-null

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text('${isEditing ? 'Edit' : 'Record'} ${selectedType ?? 'Payment'}'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // FIX: Use formKey
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Salesman>(
                        decoration: const InputDecoration(
                          labelText: 'Select Salesman',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        value: dialogSelectedSalesman,
                        items: Salesman.dummySalesmen.map((salesman) { // FIX: dummySalesmen is now correctly accessed
                          return DropdownMenuItem<Salesman>(
                            value: salesman,
                            child: Text(salesman.name), // FIX: salesman.name can't be null
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateInDialog(() { dialogSelectedSalesman = value; });
                        },
                        validator: (value) => value == null ? 'Select a salesman' : null,
                        // FIX: 'enabled' parameter removed. State is controlled by onChanged being null.
                        // For read-only when editing, you could wrap in IgnorePointer or set onChanged to null conditionally
                        // enabled: !isEditing,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (PKR)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                        validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0) ? 'Enter valid amount' : null,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Payment Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                          DropdownMenuItem(value: 'Advance', child: Text('Advance')),
                        ],
                        onChanged: (value) {
                          setStateInDialog(() { selectedType = value; });
                        },
                        validator: (value) => value == null ? 'Select payment type' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate)), // FIX: selectedDate is now non-nullable
                        decoration: const InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) { setStateInDialog(() { selectedDate = picked; }); }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) { // FIX: Use formKey
                      final newTransaction = SalesmanPayment(
                        id: isEditing ? paymentToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        salesmanId: dialogSelectedSalesman!.id,
                        salesmanName: dialogSelectedSalesman!.name,
                        date: selectedDate, // FIX: selectedDate is now non-nullable
                        amount: double.parse(amountController.text),
                        type: selectedType!,
                        description: descriptionController.text,
                      );
                      setState(() { // Update main screen's state
                        if (isEditing) {
                          final index = _allSalesmanPayments.indexWhere((p) => p.id == newTransaction.id);
                          if (index != -1) _allSalesmanPayments[index] = newTransaction;
                        } else {
                          _allSalesmanPayments.insert(0, newTransaction);
                        }
                        _allSalesmanPayments.sort((a, b) => b.date.compareTo(a.date)); // Sort by date
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newTransaction.type} payment ${isEditing ? 'updated' : 'recorded'}!')),
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Record'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      amountController.dispose();
      descriptionController.dispose();
    });
  }

  void _confirmDeletePayment(SalesmanPayment payment) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this ${payment.type} payment record (PKR ${payment.amount.toStringAsFixed(2)} to ${payment.salesmanName})?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() { _allSalesmanPayments.removeWhere((p) => p.id == payment.id); });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment record deleted!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentOptions(BuildContext context, SalesmanPayment payment) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.edit), title: const Text('Edit Payment'), onTap: () { Navigator.pop(bc); _showAddEditPaymentDialog(paymentToEdit: payment); }),
              ListTile(leading: const Icon(Icons.delete), title: const Text('Delete Payment'), onTap: () { Navigator.pop(bc); _confirmDeletePayment(payment); }),
            ],
          ),
        );
      },
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report for ${_filteredPayments.length} salesman payments...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salesman Payments'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Summary for Salesmen Payments
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Salaries Paid:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        Text(
                          'PKR ${_allSalesmanPayments.where((p) => p.type == 'Salary').fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Advances Given:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        Text(
                          'PKR ${_allSalesmanPayments.where((p) => p.type == 'Advance').fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), // Added for clarity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Outstanding Advance:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        // This calculation is more complex as it depends on advance repayments.
                        // For now, it's just total advances given from _allSalesmanPayments.
                        // In a real app, you'd calculate this from advances minus repayments.
                        Text(
                          'PKR ${_allSalesmanPayments.where((p) => p.type == 'Advance').fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Text(
              'Filter Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Salesman Filter
            DropdownButtonFormField<Salesman>(
              decoration: const InputDecoration(
                labelText: 'Filter by Salesman',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
              value: _selectedSalesmanFilter,
              items: Salesman.dummySalesmen.map((salesman) {
                return DropdownMenuItem<Salesman>(
                  value: salesman,
                  child: Text(salesman.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() { _selectedSalesmanFilter = value; });
              },
              hint: const Text('All Salesmen'),
            ),
            const SizedBox(height: 15),
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () { setState(() { _filterStartDate = null; _filterEndDate = null; _selectedSalesmanFilter = null; }); },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ),
            const SizedBox(height: 20),

            _filteredPayments.isEmpty
                ? Center(
              child: Text(
                'No salesman payments to display for this period.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = _filteredPayments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      '${payment.salesmanName} - PKR ${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${payment.type}'),
                        Text('Date: ${DateFormat('yyyy-MM-dd').format(payment.date)}'),
                        if (payment.description.isNotEmpty) Text('Desc: ${payment.description}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showPaymentOptions(context, payment),
                    ),
                  ),
                );
              },
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
        onPressed: _recordNewPayment,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}