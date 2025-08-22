import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import models
import 'package:cigarette_agency_management_app/models/company_invoice.dart'; // NEW: Import CompanyInvoice model
// Re-using DistributorPayment for individual payment transactions against invoices
import 'package:cigarette_agency_management_app/models/brand.dart'; // For dummy data if needed
import 'package:cigarette_agency_management_app/models/product.dart'; // For dummy data if needed


// Previous DistributorPayment class remains for recording payment transactions
class DistributorPayment {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'Cash', 'Online'
  final String reference; // e.g., Invoice #, bank transaction ID
  final String invoiceId; // Link to the CompanyInvoice
  final String? description; // New: description for the payment transaction

  DistributorPayment({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.reference,
    required this.invoiceId,
    this.description,
  });
}

class DistributorPaymentsScreen extends StatefulWidget { // Keeping filename as is
  const DistributorPaymentsScreen({super.key});

  @override
  State<DistributorPaymentsScreen> createState() => _DistributorPaymentsScreenState();
}

class _DistributorPaymentsScreenState extends State<DistributorPaymentsScreen> {
  // List of Company Invoices received from the company
  final List<CompanyInvoice> _companyInvoices = CompanyInvoice.dummyInvoices;

  // List of individual payment transactions made by the agency against invoices
  // This would typically be associated with invoices in a real system.
  final List<DistributorPayment> _paymentTransactions = [
    DistributorPayment(id: 'dp_tran_001', date: DateTime(2025, 7, 12), amount: 500000.0, type: 'Online', reference: 'Bank Xfer', invoiceId: 'inv001', description: 'Partial for INV-2025-001'),
  ];

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterStatus; // 'Due', 'Partially Paid', 'Paid'

  List<CompanyInvoice> get _filteredInvoices {
    return _companyInvoices.where((invoice) {
      bool matchesDateRange = (_filterStartDate == null || invoice.invoiceDate.isAfter(_filterStartDate!.subtract(const Duration(days: 1)))) &&
          (_filterEndDate == null || invoice.invoiceDate.isBefore(_filterEndDate!.add(const Duration(days: 1))));
      bool matchesStatus = _filterStatus == null || invoice.status == _filterStatus;
      return matchesDateRange && matchesStatus;
    }).toList();
  }

  void _recordNewInvoice() {
    _showAddEditInvoiceDialog();
  }

  Future<void> _showAddEditInvoiceDialog({CompanyInvoice? invoiceToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final isEditing = invoiceToEdit != null;

    final TextEditingController invoiceNumberController = TextEditingController(text: invoiceToEdit?.invoiceNumber);
    final TextEditingController totalAmountController = TextEditingController(text: invoiceToEdit?.totalAmount.toString());
    final TextEditingController stockRefController = TextEditingController(text: invoiceToEdit?.stockReference);
    DateTime _selectedDate = invoiceToEdit?.invoiceDate ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Company Invoice' : 'Record New Company Invoice'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(labelText: 'Invoice Number', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Enter invoice number' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: totalAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Amount (PKR)', border: OutlineInputBorder()),
                        validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0) ? 'Enter valid amount' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: stockRefController,
                        decoration: const InputDecoration(labelText: 'Stock Reference', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Enter stock reference' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate)),
                        decoration: const InputDecoration(labelText: 'Invoice Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101),
                          );
                          if (picked != null) setStateInDialog(() { _selectedDate = picked; });
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
                      final newInvoice = CompanyInvoice(
                        id: isEditing ? invoiceToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        invoiceNumber: invoiceNumberController.text,
                        invoiceDate: _selectedDate,
                        totalAmount: double.parse(totalAmountController.text),
                        stockReference: stockRefController.text,
                        amountPaid: isEditing ? invoiceToEdit!.amountPaid : 0.0, // Preserve paid amount if editing
                        status: isEditing ? invoiceToEdit!.status : 'Due', // Preserve status
                      );
                      setState(() {
                        if (isEditing) {
                          final index = _companyInvoices.indexWhere((inv) => inv.id == newInvoice.id);
                          if (index != -1) _companyInvoices[index] = newInvoice;
                        } else {
                          _companyInvoices.insert(0, newInvoice);
                        }
                        _companyInvoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${isEditing ? 'updated' : 'recorded'}!')));
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(isEditing ? 'Update Invoice' : 'Record Invoice'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      invoiceNumberController.dispose(); totalAmountController.dispose(); stockRefController.dispose();
    });
  }

  void _confirmDeleteInvoice(CompanyInvoice invoice) {
    showDialog(context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete invoice "${invoice.invoiceNumber}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() { _companyInvoices.removeWhere((inv) => inv.id == invoice.id); });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice deleted!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete'),
          ),
        ],
      );
    });
  }

  // --- NEW: Pay Amount Dialog ---
  Future<void> _showPayAmountDialog(CompanyInvoice invoice) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController payAmountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? selectedMethod = 'Cash'; // Default payment method

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text('Pay for Invoice ${invoice.invoiceNumber}'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Remaining Due: PKR ${invoice.remainingAmount.toStringAsFixed(2)}'),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: payAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount to Pay (PKR)', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Enter valid amount to pay';
                          }
                          if (double.parse(value) > invoice.remainingAmount) {
                            return 'Amount exceeds remaining due';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                        value: selectedMethod,
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Online', child: Text('Online Transfer')),
                        ],
                        onChanged: (value) => setStateInDialog(() { selectedMethod = value; }),
                        validator: (value) => value == null ? 'Select method' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                        maxLines: 2,
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
                      final paidAmount = double.parse(payAmountController.text);
                      setState(() { // Update main screen's state
                        invoice.amountPaid += paidAmount;
                        if (invoice.remainingAmount <= 0) {
                          invoice.status = 'Paid';
                        } else {
                          invoice.status = 'Partially Paid';
                        }
                        // Record the individual payment transaction
                        _paymentTransactions.insert(0, DistributorPayment(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          date: DateTime.now(),
                          amount: paidAmount,
                          type: selectedMethod!,
                          reference: invoice.invoiceNumber, // Reference the invoice
                          invoiceId: invoice.id,
                          description: descriptionController.text,
                        ));
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PKR ${paidAmount.toStringAsFixed(2)} paid for ${invoice.invoiceNumber}!')));
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Confirm Payment'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      payAmountController.dispose(); descriptionController.dispose();
    });
  }

  void _showInvoiceOptions(BuildContext context, CompanyInvoice invoice) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.edit), title: const Text('Edit Invoice'), onTap: () { Navigator.pop(bc); _showAddEditInvoiceDialog(invoiceToEdit: invoice); }),
              ListTile(leading: const Icon(Icons.payment), title: const Text('Record Payment'), onTap: () { Navigator.pop(bc); _showPayAmountDialog(invoice); }),
              ListTile(leading: const Icon(Icons.delete), title: const Text('Delete Invoice'), onTap: () { Navigator.pop(bc); _confirmDeleteInvoice(invoice); }),
            ],
          ),
        );
      },
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report for ${_filteredInvoices.length} invoices...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Invoices'), // Title changed
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Invoices',
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
                DropdownMenuItem(value: 'Due', child: Text('Due')),
                DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
                DropdownMenuItem(value: 'Paid', child: Text('Paid')),
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

            _filteredInvoices.isEmpty
                ? Center(
              child: Text(
                'No company invoices to display for this period.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredInvoices.length,
              itemBuilder: (context, index) {
                final invoice = _filteredInvoices[index];
                Color statusColor;
                if (invoice.status == 'Paid') statusColor = Colors.green;
                else if (invoice.status == 'Partially Paid') statusColor = Colors.orange;
                else statusColor = Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      'Invoice: ${invoice.invoiceNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)}'),
                        Text('Total: PKR ${invoice.totalAmount.toStringAsFixed(2)}'),
                        Text('Paid: PKR ${invoice.amountPaid.toStringAsFixed(2)}'),
                        Text('Due: PKR ${invoice.remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(color: invoice.remainingAmount > 0 ? Colors.red : Colors.green)),
                        Text('Stock Ref: ${invoice.stockReference}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(label: Text(invoice.status), backgroundColor: statusColor, labelStyle: const TextStyle(color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showInvoiceOptions(context, invoice),
                        ),
                      ],
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
        onPressed: _recordNewInvoice,
        icon: const Icon(Icons.add),
        label: const Text('Record Invoice'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}