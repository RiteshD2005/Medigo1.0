import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/booking_model.dart';


class UserJobDetailPage extends StatefulWidget {
  final BookingModel booking;

  const UserJobDetailPage({super.key, required this.booking});

  @override
  State<UserJobDetailPage> createState() => _UserJobDetailPageState();
}

class _UserJobDetailPageState extends State<UserJobDetailPage> {
  Map<String, dynamic>? testData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTest();
  }

  Future<void> _fetchTest() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.booking.testId)
          .get();

      if (doc.exists) {
        testData = doc.data();
      } else {
        errorMessage = "Test details not found";
      }
    } catch (e) {
      errorMessage = "Failed to load test details: $e";
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  int _extractPrice(dynamic price) {
    if (price == null) return 0;
    if (price is num) return price.toInt();
    if (price is String) {
      return int.tryParse(price.replaceAll("₹", "").trim()) ?? 0;
    }
    return 0;
  }

  Future<void> _launchReport(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid report link'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open link';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'accepted': return 'Accepted';
      case 'sample_collected': return 'Sample Collected';
      case 'completed': return 'Completed';
      case 'pending': return 'Pending';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted': return Colors.blue;
      case 'sample_collected': return Colors.purple;
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Booking Details")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                    _fetchTest();
                  });
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final booking = widget.booking;
    final testPrice = testData != null ? _extractPrice(testData!['price']) : 0;
    const bookingFee = 100;
    final gst = (bookingFee * 0.18).round();
    final totalPaid = bookingFee + gst;
    final statusColor = _getStatusColor(booking.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatStatus(booking.status).toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Test name
            Text(
              booking.testName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${testData?['category'] ?? 'Test'} • ${testData?['lab'] ?? 'Lab'}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Info cards
            _infoCard(
              title: "Customer Details",
              icon: Icons.person_outline,
              children: [
                _infoRow(Icons.location_on, "Address", booking.address),
                _infoRow(Icons.calendar_today, "Date", _formatDate(booking.date)),
              ],
            ),
            const SizedBox(height: 16),

            _infoCard(
              title: "Payment Summary",
              icon: Icons.receipt_outlined,
              children: [
                _paymentRow("Booking Fee", "₹100"),
                _paymentRow("GST (18%)", "₹$gst"),
                const Divider(),
                _paymentRow("Paid Now", "₹$totalPaid", isBold: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _paymentRow("Test Price", "₹$testPrice"),
                      _paymentRow("Pay to Technician", "₹$testPrice"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // OTP display (if accepted)
            if (booking.status == "accepted" && booking.otp != null)
              _infoCard(
                title: "Verification PIN",
                icon: Icons.lock_outline,
                backgroundColor: Colors.blue.shade50,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          booking.otp!.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Share this PIN with the technician",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Sample collected message
            if (booking.status == "sample_collected")
              _infoCard(
                title: "Sample Collected",
                icon: Icons.science_outlined,
                backgroundColor: Colors.purple.shade50,
                children: const [
                  Text("Your sample has been collected. The report will be ready soon."),
                ],
              ),

            // Report link (completed)
            if (booking.status == "completed" && booking.reportUrl != null && booking.reportUrl!.isNotEmpty)
              _infoCard(
                title: "Test Report",
                icon: Icons.description_outlined,
                backgroundColor: Colors.green.shade50,
                children: [
                  InkWell(
                    onTap: () => _launchReport(booking.reportUrl!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.open_in_new, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            "View Report",
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Unknown date';
    }
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}