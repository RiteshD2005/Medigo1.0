import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_model.dart';
import '../models/booking_model.dart';
import '../models/clinic_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TestModel>> getTests() {
    return _firestore.collection('tests').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TestModel.fromFirestore(doc)).toList();
    });
  }

  Future<TestModel> getTestById(String id) async {
    final doc = await _firestore.collection('tests').doc(id).get();
    if (!doc.exists) throw Exception('Test not found');
    return TestModel.fromFirestore(doc);
  }

  Future<List<TestModel>> getAllTests() async {
    final snapshot = await _firestore.collection('tests').get();
    return snapshot.docs.map((doc) => TestModel.fromFirestore(doc)).toList();
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();

    });

  }
  Stream<List<ClinicModel>> getClinics() {

    return FirebaseFirestore.instance
        .collection('Clinics')
        .snapshots()
        .map((snapshot) {

      return snapshot.docs
          .map((doc) => ClinicModel.fromFirestore(doc))
          .toList();

    });

  }
}