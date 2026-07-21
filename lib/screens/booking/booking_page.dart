import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/test_model.dart';
import 'payment_page.dart';

class BookingPage extends StatefulWidget {
  final TestModel test;

  const BookingPage({super.key, required this.test});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  bool _loadingAddress = true;

  double? userLat;
  double? userLng;

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserAddress() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _loadingAddress = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      setState(() {
        _addressController.text = data['address'] ?? "";

        userLat = (data['lat'] ?? 0).toDouble();
        userLng = (data['lng'] ?? 0).toDouble();

        _loadingAddress = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _proceedToPayment() {
    final address = _addressController.text.trim();

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        address.isNotEmpty) {

      final user = FirebaseAuth.instance.currentUser;

      final bookingData = {
        'userId': user!.uid,

        'testId': widget.test.id, // 🔥 IMPORTANT
        'testName': widget.test.name,
        'testCategory': widget.test.category,
        'price': widget.test.price,
        'duration': widget.test.duration,

        'address': address,
        'date': _selectedDate,

        'notes': _notesController.text,
        'lat': userLat,
        'lng': userLng,

        // 🔥 IMPORTANT (ADD THESE)
        'status': 'pending',
        'bookingFeePaid': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(bookingData: bookingData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book ${widget.test.name}"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services, color: const Color(0xFF1A73E8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.test.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            Text("${widget.test.price} • ${widget.test.duration}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address field with loading indicator
              _loadingAddress
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
                  : TextFormField(
                controller: _addressController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Collection Address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? "Select Date"
                            : DateFormat.yMMMd().format(_selectedDate!),
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: "Additional Notes (optional)",
                  hintText: "e.g., landmark, call before arrival",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Proceed button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Proceed to Pay ₹100",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}