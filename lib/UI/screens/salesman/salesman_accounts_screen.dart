// lib/UI/screens/salesman/salesman_accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';

class SalesmanAccountsScreen extends StatefulWidget {
  final Salesman salesman;

  const SalesmanAccountsScreen({super.key, required this.salesman});

  @override
  State<SalesmanAccountsScreen> createState() => _SalesmanAccountsScreenState();
}

class _SalesmanAccountsScreenState extends State<SalesmanAccountsScreen> {
  final List<SalesmanAccountTransaction> _transactions = SalesmanAccountTransaction.dummyTransactions;

  @override
  Widget build(BuildContext context) {
    // Filter transactions for the current salesman
    final List<SalesmanAccountTransaction> salesmanTransactions = _transactions
        .where((t) => t.salesmanId == widget.salesman.id)
        .toList();

    // Calculate balances
    final double totalCredit = salesmanTransactions.where((t) => t.direction == 'Credit').fold(0.0, (sum, item) => sum + item.amount);
    final double totalDebit = salesmanTransactions.where((t) => t.direction == 'Debit').fold(0.0, (sum, item) => sum + item.amount);
    final double currentBalance = totalCredit - totalDebit;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.salesman.name}\'s Account'),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.3,
              children: [
                _buildSummaryCard('Total Credit', 'PKR ${totalCredit.toStringAsFixed(2)}', Icons.arrow_upward, Colors.green),
                _buildSummaryCard('Total Debit', 'PKR ${totalDebit.toStringAsFixed(2)}', Icons.arrow_downward, Colors.red),
                _buildSummaryCard('Current Balance', 'PKR ${currentBalance.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blue),
                _buildSummaryCard('Total Outstanding', 'PKR 0.00', Icons.warning, Colors.orange), // This would be calculated from arrear records
              ],
            ),
            const SizedBox(height: 30),

            const Text('Transaction Ledger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            salesmanTransactions.isEmpty
                ? Center(
                child: Text('No transactions for this salesman.', style: TextStyle(fontSize: 16, color: Colors.grey[600])))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: salesmanTransactions.length,
              itemBuilder: (context, index) {
                final transaction = salesmanTransactions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: Icon(
                      transaction.direction == 'Credit' ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                      color: transaction.direction == 'Credit' ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      '${transaction.description} (${transaction.type})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(transaction.transactionDate)),
                    trailing: Text(
                      'PKR ${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.direction == 'Credit' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}