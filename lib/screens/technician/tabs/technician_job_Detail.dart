import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TechnicianJobDetail extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> data;

  const TechnicianJobDetail({
    super.key,
    required this.bookingId,
    required this.data,
  });

  @override
  State<TechnicianJobDetail> createState() => _TechnicianJobDetailState();
}

class _TechnicianJobDetailState extends State<TechnicianJobDetail> {
  final TextEditingController _reportLinkController = TextEditingController();
  String? reportUrl;
  bool isCompleting = false;
  bool isAddingLink = false;

  @override
  void initState() {
    super.initState();
    reportUrl = widget.data['reportUrl'];
    if (reportUrl != null && reportUrl!.isNotEmpty) {
      _reportLinkController.text = reportUrl!;
    }
  }

  @override
  void dispose() {
    _reportLinkController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveReportLink() async {
    final link = _reportLinkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid link'), backgroundColor: Colors.red),
      );
      return;
    }
    // Basic URL validation
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link must start with http:// or https://'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => isAddingLink = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'reportUrl': link,
      });
      setState(() {
        reportUrl = link;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Report link saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isAddingLink = false);
    }
  }

  Future<void> _completeTest() async {
    if (reportUrl == null || reportUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a report link first'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => isCompleting = true);
    try {
      final earnings = 100 + _extractPrice(widget.data['price']);
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'technicianEarning': earnings,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Test Completed')),
        );
        setState(() {
          widget.data['status'] = 'completed';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Job Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.data['userId'])
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }
          final user = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Test Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("🧪 ${widget.data['testName']}"),
                  Text("🏥 ${widget.data['lab']}"),
                  Text("📅 ${_formatDate(widget.data['date'])}"),
                  const SizedBox(height: 20),
                  const Text(
                    "Customer Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("👤 ${user['name']}"),
                  Text("📞 ${user['phone'] ?? 'No phone'}"),
                  Text("📍 ${user['address']}"),
                  const SizedBox(height: 20),
                  // Call & Directions buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final phone = user['phone'];
                            if (phone != null && phone.isNotEmpty) {
                              final url = Uri.tryParse("tel:$phone");
                              if (url != null && await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            }
                          },
                          icon: const Icon(Icons.call),
                          label: const Text("Call"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final lat = widget.data['lat'];
                            final lng = widget.data['lng'];
                            final url = Uri.tryParse(
                                "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
                            if (url != null && await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text("Directions"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Payment Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _row("Booking Fee", "₹100"),
                        _row("Technician Service Fee", "₹100"),
                        const Divider(),
                        _row("Test Price", widget.data['price'] ?? "₹0"),
                        const Divider(),
                        _row(
                          "Your Earnings",
                          "₹${100}",
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // OTP verification
                  if (widget.data['status'] == 'accepted') ...[
                    ElevatedButton(
                      onPressed: () => _verifyOtp(context),
                      child: const Text("Enter OTP"),
                    ),
                  ],
                  // Report link input (instead of file upload)
                  if (widget.data['status'] == 'sample_collected') ...[
                    const Text(
                      "Report Link (Google Drive, Dropbox, etc.)",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reportLinkController,
                      decoration: InputDecoration(
                        hintText: "https://drive.google.com/...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: isAddingLink
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.save),
                          onPressed: isAddingLink ? null : _saveReportLink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (reportUrl != null && reportUrl!.isNotEmpty)
                      InkWell(
                        onTap: () => _launchUrl(reportUrl!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reportUrl!,
                                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isCompleting ? null : _completeTest,
                      child: isCompleting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text("Complete Test"),
                    ),
                  ],
                  // Completed UI
                  if (widget.data['status'] == 'completed') ...[
                    const Text(
                      "✅ Test Completed",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    if (reportUrl != null && reportUrl!.isNotEmpty)
                      InkWell(
                        onTap: () => _launchUrl(reportUrl!),
                        child: const Text(
                          "View Report",
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return timestamp.toString();
  }

  Widget _row(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  int _extractPrice(String price) {
    return int.tryParse(price.replaceAll("₹", "").trim()) ?? 0;
  }

  void _verifyOtp(BuildContext context) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter PIN"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "123456"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final doc = await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .get();
              final freshData = doc.data()!;
              if (freshData['status'] != 'accepted') {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("OTP already used")),
                );
                return;
              }
              final realOtp = freshData['otp'];
              if (controller.text == realOtp) {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(widget.bookingId)
                    .update({
                  'status': 'sample_collected',
                  'otp': null,
                  'sampleCollectedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sample Collected")),
                );
                setState(() {
                  widget.data['status'] = 'sample_collected';
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Wrong PIN")),
                );
              }
            },
            child: const Text("Verify"),
          )
        ],
      ),
    );
  }
}