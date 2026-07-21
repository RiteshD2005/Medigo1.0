import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/test_model.dart';
import '../booking/booking_page.dart';
import '../../services/firestore_service.dart';

class TestDetailPage extends StatelessWidget {
  final String testId;
  const TestDetailPage({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Details")),
      body: FutureBuilder<TestModel>(
        future: FirestoreService().getTestById(testId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Test not found"));
          }
          final test = snapshot.data!;
          return _buildContent(context, test);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TestModel test) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(test.name, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("${test.category} • ${test.lab}", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoCard(Icons.currency_rupee, "Price", test.price)),
              const SizedBox(width: 12),
              Expanded(child: _infoCard(Icons.access_time, "Report Time", test.duration)),
            ],
          ),
          const SizedBox(height: 24),
          _section("Preparation Instructions", test.preparation),
          const SizedBox(height: 24),
          _section("About this test", test.description),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookingPage(test: test)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text("Book this test", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1A73E8)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: title.contains("Preparation") ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(content, style: GoogleFonts.poppins(fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }
}