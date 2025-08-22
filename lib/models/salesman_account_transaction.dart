// lib/models/salesman_account_transaction.dart

class SalesmanAccountTransaction {
  final String id;
  final String salesmanId;
  final String description;
  final DateTime transactionDate;
  final double amount;
  final String type; // e.g., 'Stock Out', 'Cash Received', 'Salary Paid', 'Advance'
  final String direction; // 'Credit' (money owed to salesman), 'Debit' (money owed by salesman)

  SalesmanAccountTransaction({
    required this.id,
    required this.salesmanId,
    required this.description,
    required this.transactionDate,
    required this.amount,
    required this.type,
    required this.direction,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is SalesmanAccountTransaction && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  static List<SalesmanAccountTransaction> get dummyTransactions => [
    SalesmanAccountTransaction(
        id: 'sat001', salesmanId: 's001', description: 'July Salary', transactionDate: DateTime(2025, 7, 25), amount: 35000.0, type: 'Salary Paid', direction: 'Credit'),
    SalesmanAccountTransaction(
        id: 'sat002', salesmanId: 's001', description: 'Stock out - Marlboro', transactionDate: DateTime(2025, 7, 22), amount: 12500.0, type: 'Stock Out', direction: 'Debit'),
    SalesmanAccountTransaction(
        id: 'sat003', salesmanId: 's001', description: 'Cash collected', transactionDate: DateTime(2025, 7, 22), amount: 8000.0, type: 'Cash Received', direction: 'Credit'),
    SalesmanAccountTransaction(
        id: 'sat004', salesmanId: 's002', description: 'Advance payment', transactionDate: DateTime(2025, 7, 20), amount: 5000.0, type: 'Advance', direction: 'Debit'),
    SalesmanAccountTransaction(
        id: 'sat005', salesmanId: 's001', description: 'Stock out - Dunhill', transactionDate: DateTime(2025, 7, 18), amount: 20000.0, type: 'Stock Out', direction: 'Debit'),
  ];
}