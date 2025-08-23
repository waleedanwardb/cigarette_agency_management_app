// lib/UI/screens/salesman/salesman_accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_stock_detail_screen.dart'; // Import the target screen

class SalesmanAccountsScreen extends StatefulWidget {
  final Salesman salesman;

  const SalesmanAccountsScreen({super.key, required this.salesman});

  @override
  State<SalesmanAccountsScreen> createState() => _SalesmanAccountsScreenState();
}

class _SalesmanAccountsScreenState extends State<SalesmanAccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final salesmanService = Provider.of<SalesmanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.salesman.name}\'s Account'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<SalesmanAccountTransaction>>(
        stream: salesmanService.getSalesmanTransactions(widget.salesman.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No transactions found for this salesman.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          final salesmanTransactions = snapshot.data!;

          // Calculate balances from the fetched transactions
          final double totalCredit = salesmanTransactions
              .where((t) => t.cashReceived != null && t.cashReceived! > 0)
              .fold(0.0, (sum, item) => sum + item.cashReceived!);
          final double totalDebit = salesmanTransactions
              .where((t) => t.calculatedPrice != null && t.calculatedPrice! > 0)
              .fold(0.0, (sum, item) => sum + item.calculatedPrice!);
          final double currentBalance = totalCredit - totalDebit;

          return SingleChildScrollView(
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
                    _buildSummaryCard('Total Outstanding', 'PKR ${(-currentBalance).toStringAsFixed(2)}', Icons.warning, Colors.orange),
                  ],
                ),
                const SizedBox(height: 30),

                const Text('Transaction Ledger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: salesmanTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = salesmanTransactions[index];
                    String transactionTitle;
                    String transactionAmount;
                    Color amountColor;
                    IconData amountIcon;

                    if (transaction.type == 'Cash Received') {
                      transactionTitle = '${transaction.description} (${transaction.type})';
                      transactionAmount = 'PKR ${transaction.cashReceived?.toStringAsFixed(2) ?? '0.00'}';
                      amountColor = Colors.green;
                      amountIcon = Icons.arrow_circle_up;
                    } else { // Assuming 'Stock Out', 'Stock Return' are the other types
                      transactionTitle = '${transaction.description} (${transaction.type})';
                      transactionAmount = 'PKR ${transaction.calculatedPrice?.toStringAsFixed(2) ?? '0.00'}';
                      amountColor = Colors.red;
                      amountIcon = Icons.arrow_circle_down;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: 2,
                      child: ListTile(
                        onTap: () {
                          // Navigate to SalesmanStockDetailScreen on tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalesmanStockDetailScreen(salesman: widget.salesman),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: Icon(
                          amountIcon,
                          color: amountColor,
                        ),
                        title: Text(
                          transactionTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(transaction.date.toDate())),
                        trailing: Text(
                          transactionAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
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