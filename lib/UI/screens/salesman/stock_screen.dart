// lib/UI/screens/salesman/stock_screen.dart
import 'package:flutter/material.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/record_stock_out_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/record_stock_return_screen.dart';

class StockScreen extends StatelessWidget {
  final Salesman salesman;

  const StockScreen({super.key, required this.salesman});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Record Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RecordStockOutScreen(salesman: salesman),
                  ),
                );
              },
              icon: const Icon(Icons.outbox),
              label: const Text('Record Stock Out'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RecordStockReturnScreen(salesman: salesman),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_return),
              label: const Text('Record Stock Return'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}