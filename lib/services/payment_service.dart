// lib/services/payment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cigarette_agency_management_app/models/payment.dart';

class PaymentService {
  final CollectionReference _paymentsCollection =
  FirebaseFirestore.instance.collection('payments');

  Future<void> addPayment(Payment payment) async {
    await _paymentsCollection.add(payment.toFirestore());
  }

  Stream<List<Payment>> getPayments() {
    return _paymentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

// You can add more methods here as needed, like getting payments by type or reference ID.
}