// lib/UI/screens/salesman/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';
import 'package:cigarette_agency_management_app/models/arrear.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/record_stock_out_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/record_stock_return_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final Salesman salesman;
  final List<SalesmanAccountTransaction> allTransactions;

  const TransactionsScreen({super.key, required this.salesman, required this.allTransactions});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating report... (Feature coming soon)'),
      ),
    );
  }

  Map<String, List<SalesmanAccountTransaction>> _groupTransactionsByDate(
      List<SalesmanAccountTransaction> transactions) {
    Map<String, List<SalesmanAccountTransaction>> groupedData = {};

    for (var transaction in transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(transaction.date.toDate());
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(transaction);
    }
    return groupedData;
  }

  void _deleteTransaction(SalesmanAccountTransaction transaction) {
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                salesmanService.deleteSalesmanTransaction(widget.salesman.id, transaction.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteAllTransactionsOnDate(List<SalesmanAccountTransaction> transactions) {
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete All'),
          content: const Text('Are you sure you want to delete all transactions for this day?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete All'),
              onPressed: () async {
                for (var transaction in transactions) {
                  await salesmanService.deleteSalesmanTransaction(widget.salesman.id, transaction.id);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All transactions for the day deleted successfully!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _calculateDailyTotals(List<SalesmanAccountTransaction> transactions) {
    double totalStockOutPacks = 0.0;
    double totalStockReturnPacks = 0.0;
    double totalCashReceived = 0.0;
    double totalGrossAmount = 0.0;
    double totalSchemeDiscount = 0.0;
    double totalFinalAmount = 0.0;

    for (var transaction in transactions) {
      if (transaction.type == 'Stock Out') {
        totalStockOutPacks += transaction.stockOutQuantity ?? 0.0;
        totalGrossAmount += transaction.grossPrice ?? 0.0;
        totalSchemeDiscount += transaction.totalSchemeDiscount ?? 0.0;
        totalFinalAmount += transaction.calculatedPrice ?? 0.0;
      } else if (transaction.type == 'Stock Return') {
        totalStockReturnPacks += transaction.stockReturnQuantity ?? 0.0;
        // Correctly subtract returned values
        totalGrossAmount += transaction.grossPrice ?? 0.0;
        totalSchemeDiscount += transaction.totalSchemeDiscount ?? 0.0;
        totalFinalAmount += transaction.calculatedPrice ?? 0.0;
      } else if (transaction.type == 'Cash Received') {
        totalCashReceived += transaction.cashReceived ?? 0.0;
      }
    }

    // The final amount is the total of all transactions (sales and returns)
    // minus the cash received.
    double totalNetBalance = totalFinalAmount - totalCashReceived;

    return {
      'stockOutPacks': totalStockOutPacks,
      'stockReturnPacks': totalStockReturnPacks,
      'cashReceived': totalCashReceived,
      'grossAmount': totalGrossAmount,
      'schemeDiscount': totalSchemeDiscount,
      'finalAmount': totalFinalAmount,
      'netBalance': totalNetBalance,
    };
  }

  @override
  Widget build(BuildContext context) {
    List<SalesmanAccountTransaction> filteredTransactions = widget.allTransactions.where((transaction) {
      final transactionDate = transaction.date.toDate();
      bool matchesStartDate = _filterStartDate == null ||
          transactionDate.isAtSameMomentAs(_filterStartDate!) ||
          transactionDate.isAfter(_filterStartDate!);
      bool matchesEndDate = _filterEndDate == null ||
          transactionDate.isAtSameMomentAs(_filterEndDate!) ||
          transactionDate.isBefore(_filterEndDate!.add(const Duration(days: 1)));
      return matchesStartDate && matchesEndDate;
    }).toList();

    final groupedData = _groupTransactionsByDate(filteredTransactions);
    final sortedDates = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

    final allTransactionsTotal = _calculateDailyTotals(filteredTransactions);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Summary for Selected Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Total Stock Out: ${allTransactionsTotal['stockOutPacks']?.toStringAsFixed(0)} Packs'),
                    Text('Total Stock Return: ${allTransactionsTotal['stockReturnPacks']?.toStringAsFixed(0)} Packs'),
                    Text('Total Cash Received: PKR ${allTransactionsTotal['cashReceived']?.toStringAsFixed(2)}'),
                    Text('Total Transaction Value: PKR ${allTransactionsTotal['finalAmount']?.toStringAsFixed(2)}'),
                    Text('Total Scheme Discount: PKR ${allTransactionsTotal['schemeDiscount']?.toStringAsFixed(2)}'),
                    Text('Net Balance: PKR ${allTransactionsTotal['netBalance']?.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Filter Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: _filterStartDate == null
                            ? ''
                            : DateFormat('yyyy-MM-dd')
                            .format(_filterStartDate!)),
                    decoration: const InputDecoration(
                      labelText: 'From Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _filterStartDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        if (!mounted) return;
                        setState(() {
                          _filterStartDate = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: _filterEndDate == null
                            ? ''
                            : DateFormat('yyyy-MM-dd')
                            .format(_filterEndDate!)),
                    decoration: const InputDecoration(
                      labelText: 'To Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _filterEndDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        if (!mounted) return;
                        setState(() {
                          _filterEndDate = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filterStartDate = null;
                    _filterEndDate = null;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Daily Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (groupedData.isEmpty)
              const Center(child: Text('No transactions found.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final transactionsForDate = groupedData[date]!;
                  final dailyTotals = _calculateDailyTotals(transactionsForDate);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 2,
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAllTransactionsOnDate(transactionsForDate),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Daily Summary:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('Stock Out: ${dailyTotals['stockOutPacks']?.toStringAsFixed(0)} Packs'),
                              Text('Stock Return: ${dailyTotals['stockReturnPacks']?.toStringAsFixed(0)} Packs'),
                              Text('Cash Received: PKR ${dailyTotals['cashReceived']?.toStringAsFixed(2)}'),
                              Text('Gross Amount: PKR ${dailyTotals['grossAmount']?.toStringAsFixed(2)}'),
                              Text('Scheme Discount: PKR ${dailyTotals['schemeDiscount']?.toStringAsFixed(2)}'),
                              Text('Final Amount: PKR ${dailyTotals['finalAmount']?.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Net Balance: PKR ${dailyTotals['netBalance']?.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              const Divider(),
                              const Text('Detailed Transactions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 12.0,
                                  dataRowMinHeight: 40,
                                  dataRowMaxHeight: 60,
                                  columns: const [
                                    DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Out', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Return', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Scheme Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Total/Final', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: transactionsForDate.map((t) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(t.productName ?? t.description)),
                                        DataCell(Text(t.type ?? '-')),
                                        DataCell(Text(t.stockOutQuantity?.toStringAsFixed(0) ?? '-')),
                                        DataCell(Text(t.stockReturnQuantity?.toStringAsFixed(0) ?? '-')),
                                        DataCell(Text(t.grossPrice?.toStringAsFixed(2) ?? '-')),
                                        DataCell(Text(t.totalSchemeDiscount?.toStringAsFixed(2) ?? '-')),
                                        DataCell(Text(t.calculatedPrice?.toStringAsFixed(2) ?? '-')),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () {
                                                  if (t.type == 'Stock Out') {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => RecordStockOutScreen(
                                                          salesman: widget.salesman,
                                                          transaction: t,
                                                        ),
                                                      ),
                                                    );
                                                  } else if (t.type == 'Stock Return' || t.type == 'Cash Received') {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => RecordStockReturnScreen(
                                                          salesman: widget.salesman,
                                                          transaction: t,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteTransaction(t),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
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
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}