import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'technician_job_detail.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  late final String _technicianId;
  bool? _isVerified; // null = loading

  @override
  void initState() {
    super.initState();
    _technicianId = FirebaseAuth.instance.currentUser!.uid;
    _fetchVerificationStatus();
  }

  Future<void> _fetchVerificationStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_technicianId)
        .get();
    if (doc.exists) {
      setState(() {
        _isVerified = doc.data()?['verified'] ?? false;
      });
    } else {
      setState(() {
        _isVerified = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchVerificationStatus();
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          // Pending Jobs Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Pending Jobs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _PendingJobsStream(
              technicianId: _technicianId,
              isVerified: _isVerified!,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // My Accepted Jobs Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'My Accepted Jobs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _AcceptedJobsStream(technicianId: _technicianId),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ==================================================
// Pending Jobs Stream (with Accept/Reject)
// ==================================================
class _PendingJobsStream extends StatefulWidget {
  final String technicianId;
  final bool isVerified;
  const _PendingJobsStream({required this.technicianId, required this.isVerified});

  @override
  State<_PendingJobsStream> createState() => _PendingJobsStreamState();
}

class _PendingJobsStreamState extends State<_PendingJobsStream> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No pending Requests')),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _JobCard(
              jobId: doc.id,
              data: data,
              technicianId: widget.technicianId,
              isPending: true,
              isVerified: widget.isVerified,
            );
          }).toList(),
        );
      },
    );
  }
}

// ==================================================
// Accepted Jobs Stream (read‑only)
// ==================================================
class _AcceptedJobsStream extends StatelessWidget {
  final String technicianId;
  const _AcceptedJobsStream({required this.technicianId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('technicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No accepted jobs yet')),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _JobCard(
              jobId: doc.id,
              data: data,
              technicianId: technicianId,
              isPending: false,
              isVerified: true, // not used for accepted jobs, but required
            );
          }).toList(),
        );
      },
    );
  }
}

// ==================================================
// Reusable Job Card
// ==================================================
class _JobCard extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> data;
  final String technicianId;
  final bool isPending;
  final bool isVerified;

  const _JobCard({
    required this.jobId,
    required this.data,
    required this.technicianId,
    required this.isPending,
    required this.isVerified,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _isLoading = false;

  Future<void> _acceptJob() async {
    setState(() => _isLoading = true);
    final pin = (1000 + Random().nextInt(9000)).toString();

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.jobId)
          .update({
        'status': 'accepted',
        'technicianId': widget.technicianId,
        'acceptedAt': FieldValue.serverTimestamp(),
        'otp': pin,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Accept Job"),
        content: const Text("Are you sure you want to accept this job?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptJob();
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectJob(String? reason) async {
    setState(() => _isLoading = true);
    try {
      final updateData = {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      };
      if (reason != null && reason.trim().isNotEmpty) {
        updateData['rejectionReason'] = reason.trim();
      }
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.jobId)
          .update(updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Reject Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You can optionally provide a reason:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(context);
              _rejectJob(reason.isEmpty ? null : reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final bool canAccept = widget.isPending && widget.isVerified;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['testName'] ?? 'Unnamed Test',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (data['testCategory'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Category: ${data['testCategory']}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on, data['address'] ?? 'No address'),
            _infoRow(Icons.calendar_today, _formatDate(data['date'])),
            if (data['price'] != null || data['duration'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (data['price'] != null)
                      Text('💰 ${data['price']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (data['price'] != null && data['duration'] != null)
                      const SizedBox(width: 12),
                    if (data['duration'] != null)
                      Text('⏱️ ${data['duration']}'),
                  ],
                ),
              ),
            if (data['notes'] != null && data['notes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '📝 Note: ${data['notes']}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),

            if (widget.isPending)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canAccept && !_isLoading ? _showAcceptDialog : null,
                          icon: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canAccept && !_isLoading ? _showRejectDialog : null,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ Your account is pending verification. You cannot accept jobs until approved by admin.',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                      ),
                    ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TechnicianJobDetail(
                          bookingId: widget.jobId,
                          data: widget.data,
                        ),
                      ),
                    );
                  },
                  child: const Text("View Details"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }
}