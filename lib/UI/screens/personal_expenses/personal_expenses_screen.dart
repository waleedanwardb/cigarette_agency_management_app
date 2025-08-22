import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dashboard/dashboard_screen.dart';
import '../home_screen/home_screen.dart';
import '../payments/payments_main_screen.dart';
import '../stock/stock_main_screen.dart';


// Dummy data for a Personal Expense (unchanged)
class PersonalExpense {
  final String id; // Added ID for uniqueness
  final String type; // e.g., 'Food', 'Transport', 'Utilities', 'Miscellaneous'
  final String description;
  final double amount;
  final DateTime date; // Changed to DateTime for proper sorting/filtering

  PersonalExpense({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
  });

  // Helper to create a copy for potential editing
  PersonalExpense copyWith({
    String? type,
    String? description,
    double? amount,
    DateTime? date,
  }) {
    return PersonalExpense(
      id: this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}

class PersonalExpensesScreen extends StatefulWidget {
  const PersonalExpensesScreen({super.key});

  @override
  State<PersonalExpensesScreen> createState() => _PersonalExpensesScreenState();
}

class _PersonalExpensesScreenState extends State<PersonalExpensesScreen> {
  int _selectedIndex = 3; // Assuming Finance is the 4th item (index 3) in bottom nav

  // --- Date filter state variables ---
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  // Dummy list of expenses (updated to use DateTime and include IDs)
  final List<PersonalExpense> _expenses = [
    PersonalExpense(
        id: 'pe001', type: 'Food', description: 'Lunch with client', amount: 500.00, date: DateTime(2025, 7, 25)),
    PersonalExpense(
        id: 'pe002', type: 'Transport', description: 'Fuel for personal car', amount: 1500.00, date: DateTime(2025, 7, 20)),
    PersonalExpense(
        id: 'pe003', type: 'Utilities', description: 'Home internet bill', amount: 1200.00, date: DateTime(2025, 7, 1)),
    PersonalExpense(
        id: 'pe004', type: 'Miscellaneous', description: 'Small office supplies', amount: 300.00, date: DateTime(2025, 6, 28)),
    PersonalExpense(
        id: 'pe005', type: 'Food', description: 'Dinner with family', amount: 800.00, date: DateTime(2025, 6, 15)),
    PersonalExpense(
        id: 'pe006', type: 'Transport', description: 'Taxi to airport', amount: 1000.00, date: DateTime(2025, 5, 10)),
  ];

  // --- Getter for filtered expenses ---
  List<PersonalExpense> get _filteredExpenses {
    return _expenses.where((expense) {
      bool matchesDateRange = (_filterStartDate == null || expense.date.isAfter(_filterStartDate!.subtract(const Duration(days: 1)))) &&
          (_filterEndDate == null || expense.date.isBefore(_filterEndDate!.add(const Duration(days: 1))));
      return matchesDateRange;
    }).toList();
  }

  // --- Getter for month-wise grouped expenses ---
  Map<String, List<PersonalExpense>> get _groupedExpensesByMonth {
    final Map<String, List<PersonalExpense>> grouped = {};
    for (var expense in _filteredExpenses) { // Group filtered expenses
      final monthYear = DateFormat('MMMM yyyy').format(expense.date);
      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(expense);
    }
    // Sort expenses within each month by date
    grouped.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
    });

    return grouped;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Implement navigation for bottom nav
  }

  // --- Helper for Add/Edit Expense Dialog ---
  Future<void> _showAddEditExpenseDialog({PersonalExpense? expenseToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final isEditing = expenseToEdit != null;

    final TextEditingController descriptionController = TextEditingController(text: expenseToEdit?.description);
    final TextEditingController amountController = TextEditingController(text: expenseToEdit?.amount.toString());
    DateTime? date = expenseToEdit?.date ?? DateTime.now();
    String? selectedType = expenseToEdit?.type; // Assuming expense types exist

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Expense' : 'Add New Expense'),
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
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Expense Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: selectedType,
                        items: const [ // Dummy expense types
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                          DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                          DropdownMenuItem(value: 'Miscellaneous', child: Text('Miscellaneous')),
                        ],
                        onChanged: (value) { setStateInDialog(() { selectedType = value; }); },
                        validator: (value) => value == null ? 'Select expense type' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(date!)),
                        decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context, initialDate: date!, firstDate: DateTime(2000), lastDate: DateTime(2101),
                          );
                          if (picked != null) { setStateInDialog(() { date = picked; }); }
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
                      final newExpense = PersonalExpense(
                        id: isEditing ? expenseToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        description: descriptionController.text,
                        amount: double.parse(amountController.text),
                        type: selectedType!,
                        date: date!,
                      );
                      setState(() { // Update main screen's state
                        if (isEditing) {
                          final index = _expenses.indexWhere((e) => e.id == newExpense.id);
                          if (index != -1) _expenses[index] = newExpense;
                        } else {
                          _expenses.insert(0, newExpense);
                        }
                        _expenses.sort((a, b) => b.date.compareTo(a.date)); // Re-sort after add/edit
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense ${isEditing ? 'updated' : 'added'}!')));
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      descriptionController.dispose(); amountController.dispose();
    });
  }

  void _confirmDeleteExpense(PersonalExpense expense) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this expense (PKR ${expense.amount.toStringAsFixed(2)})?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() { _expenses.removeWhere((e) => e.id == expense.id); });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseOptions(BuildContext context, PersonalExpense expense) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.edit), title: const Text('Edit Expense'), onTap: () { Navigator.pop(bc); _showAddEditExpenseDialog(expenseToEdit: expense); }),
              ListTile(leading: const Icon(Icons.delete), title: const Text('Delete Expense'), onTap: () { Navigator.pop(bc); _confirmDeleteExpense(expense); }),
            ],
          ),
        );
      },
    );
  }

  // --- NEW: Generate Report Method ---
  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report for ${_filteredExpenses.length} personal expenses... (Placeholder)')),
    );
    // In a real app, you'd use _filteredExpenses list to generate an Excel/PDF report.
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personal Expenses',
          style: TextStyle(fontSize: 18),
        ),
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
            // Overall Summary of personal expenses for the filtered period
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Expenses (${_filterStartDate == null && _filterEndDate == null ? 'All Time' : 'Filtered Period'}):',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    Text(
                      'PKR ${_filteredExpenses.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- NEW: Filter Options ---
            const Text(
              'Filter Expenses',
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () { setState(() { _filterStartDate = null; _filterEndDate = null; }); },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ),
            const SizedBox(height: 20),

            // --- NEW: Generate Report Button ---
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
            const SizedBox(height: 20),

            // --- Month-wise grouped expenses display ---
            Expanded( // Expanded is needed for the ListView.builder inside a Column
              child: _filteredExpenses.isEmpty
                  ? Center(
                child: Text(
                  'No expenses to display for this period.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
                  : ListView.builder(
                itemCount: _groupedExpensesByMonth.keys.length,
                itemBuilder: (context, index) {
                  final monthYear = _groupedExpensesByMonth.keys.elementAt(index);
                  final expensesInMonth = _groupedExpensesByMonth[monthYear]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Text(
                          monthYear,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true, // Important for nested ListView.builder
                        physics: const NeverScrollableScrollPhysics(), // Important
                        itemCount: expensesInMonth.length,
                        itemBuilder: (context, idx) {
                          final expense = expensesInMonth[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              title: Text(
                                expense.description,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${expense.type}'),
                                  Text('Date: ${DateFormat('yyyy-MM-dd').format(expense.date)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'PKR ${expense.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _showExpenseOptions(context, expense),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditExpenseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
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
        currentIndex: _selectedIndex, // Maintain selected index visually
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