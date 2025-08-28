// lib/UI/screens/salesman/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/models/salesman_account_transaction.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';

class DashboardScreen extends StatelessWidget {
  final Salesman salesman;
  final List<SalesmanAccountTransaction> allTransactions;

  const DashboardScreen({
    super.key,
    required this.salesman,
    required this.allTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);

    double stockOutValue = allTransactions
        .where((t) => t.type == 'Stock Out')
        .fold(0.0, (sum, t) => sum + (t.calculatedPrice ?? 0));
    double stockReturnValue = allTransactions
        .where((t) => t.type == 'Stock Return')
        .fold(0.0, (sum, t) => sum + (t.calculatedPrice ?? 0));
    double totalCashReceived = allTransactions
        .where((t) => t.type == 'Cash Received')
        .fold(0.0, (sum, t) => sum + (t.cashReceived ?? 0));
    double totalStockAssigned = allTransactions
        .where((t) => t.type == 'Stock Out')
        .fold(0.0, (sum, t) => sum + (t.stockOutQuantity ?? 0));
    double totalStockReturned = allTransactions
        .where((t) => t.type == 'Stock Return')
        .fold(0.0, (sum, t) => sum + (t.stockReturnQuantity ?? 0));

    double totalTransactionValue = stockOutValue - stockReturnValue;
    double balanceDue = totalTransactionValue - totalCashReceived;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.2,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                String title;
                String value;
                IconData icon;
                Color color;

                switch (index) {
                  case 0:
                    title = 'Stock Assigned';
                    value = (totalStockAssigned - totalStockReturned)
                        .toStringAsFixed(0) +
                        ' Packs';
                    icon = Icons.assignment_turned_in;
                    color = Colors.blue;
                    break;
                  case 1:
                    title = 'Stock Value';
                    value = 'PKR ${totalTransactionValue.toStringAsFixed(2)}';
                    icon = Icons.shopping_cart;
                    color = Colors.green;
                    break;
                  case 2:
                    title = 'Amount Received';
                    value = 'PKR ${totalCashReceived.toStringAsFixed(2)}';
                    icon = Icons.payments;
                    color = Colors.orange;
                    break;
                  case 3:
                    title = 'Balance Due';
                    value = 'PKR ${balanceDue.toStringAsFixed(2)}';
                    icon = Icons.account_balance_wallet;
                    color = Colors.red;
                    break;
                  default:
                    title = '';
                    value = '';
                    icon = Icons.help;
                    color = Colors.grey;
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(icon, color: color, size: 28),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                            Text(
                              value,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            // You can add more widgets here for the dashboard if needed
          ],
        ),
      ),
    );
  }
}