import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String userId;
  final String? technicianId;

  final String testId;

  final String testName;
  final String testCategory;
  final String technicianEarning;

  final String address;
  final double lat;
  final double lng;

  final DateTime date;
  final String status;
  final String? otp;
  String? reportUrl;

  final bool bookingFeePaid;
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.userId,
    this.technicianId,
    required this.testId,
    required this.testName,
    required this.testCategory,
    required this.address,
    required this.lat,
    required this.lng,
    required this.date,
    required this.status,
    this.otp,
    this.reportUrl,
    required this.technicianEarning,
    required this.bookingFeePaid,
    required this.createdAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert technicianEarning safely
    String technicianEarningStr = '0';
    final techEarning = data['technicianEarning'];
    if (techEarning is String) {
      technicianEarningStr = techEarning;
    } else if (techEarning is num) {
      technicianEarningStr = techEarning.toString();
    }

    return BookingModel(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      technicianId: data['technicianId'],
      testId: data['testId'] ?? '',
      testName: data['testName'] ?? '',
      testCategory: data['testCategory'] ?? '',
      technicianEarning: technicianEarningStr,
      address: data['address'] ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      otp: data['otp']?.toString(), // Convert OTP to string if needed
      reportUrl: data['reportUrl'],
      bookingFeePaid: data['bookingFeePaid'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}