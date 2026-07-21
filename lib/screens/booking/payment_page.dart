import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/test_model.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentPage({super.key, required this.bookingData});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;

  Future<void> _confirmBooking() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final bookingRef =
      FirebaseFirestore.instance.collection('bookings').doc();

      await bookingRef.set({
        // 🔥 USER
        'userId': user.uid,

        // 🔥 TEST DETAILS (already passed properly from BookingPage)
        'testId': widget.bookingData['testId'], // 🔥 CRITICAL
        'testName': widget.bookingData['testName'],
        'testCategory': widget.bookingData['testCategory'],
        'price': widget.bookingData['price'],
        'duration': widget.bookingData['duration'],

        // 🔥 LOCATION (VERY IMPORTANT)
        'address': widget.bookingData['address'],
        'lat': widget.bookingData['lat'],
        'lng': widget.bookingData['lng'],


        // 🔥 BOOKING INFO
        'date': Timestamp.fromDate(widget.bookingData['date']),
        'notes': widget.bookingData['notes'] ?? "",

        // 🔥 SYSTEM FIELDS
        'bookingFeePaid': true,
        'status': 'pending', // ✅ IMPORTANT FIX
        'technicianId': null, // for future assignment
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Icon(Icons.check_circle,
                color: Colors.green, size: 48),
            content: const Text(
                "Booking Confirmed! Technician will be assigned soon."),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text("Go Home"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bookingFee = 100;

    final testName = widget.bookingData['testName'] ?? '';
    final priceString = widget.bookingData['price'] ?? '₹0';

    final technicianFee =
        int.tryParse(priceString.replaceAll("₹", "").trim()) ?? 0;

    final gst = (bookingFee * 0.18).round();
    final total = bookingFee + gst;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Receipt Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Payment Receipt", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _receiptRow("Booking Fee", "₹$bookingFee"),
                    _receiptRow("GST (18%)", "₹$gst"),
                    const Divider(),
                    _receiptRow("Total (pay now)", "₹$total", isBold: true, color: const Color(0xFF1A73E8)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey.shade100,
                      child: Column(
                        children: [
                          Text("Technician Fee", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          Text("₹$technicianFee", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Pay directly to technician on visit", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // UPI QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text("Scan QR to Pay ₹$total", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Image.asset("assets/qr_code.png", height: 180, width: 180), // Replace with your QR asset
                  const SizedBox(height: 8),
                  Text("UPI ID: medigo@okhdfcbank", style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm button (after manual payment)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("I have paid ₹$total", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
          Text(amount, style: GoogleFonts.poppins(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}