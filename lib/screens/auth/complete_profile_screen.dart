import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../home/role_redirect.dart';
import '../location/location_picker.dart';
import '../../widgets/role_selector.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final experienceController = TextEditingController();
  final documentLinkController = TextEditingController();

  double? lat;
  double? lng;
  bool isLoading = false;
  String role = ""; // empty means not selected yet
  String? selectedClinicId;
  String? selectedClinicName;
  String? selectedClinicAddress;
  List<Map<String, dynamic>> clinics = [];
  bool isLoadingClinics = false;
  String? clinicError;

  final auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          role = data['role'] ?? "";
        });
      }
    }
  }

  Future<void> _loadClinics() async {
    setState(() {
      isLoadingClinics = true;
      clinicError = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Clinics')
          .get();
      setState(() {
        clinics = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'address': doc['address'],
          };
        }).toList();
        isLoadingClinics = false;
      });
    } catch (e) {
      setState(() {
        clinicError = "Failed to load clinics. Please try again.";
        isLoadingClinics = false;
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPicker()),
    );
    if (result != null) {
      setState(() {
        lat = result['lat'];
        lng = result['lng'];
        addressController.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (phoneController.text.trim().isEmpty) {
      _showError("Enter phone number");
      return;
    }
    if (lat == null || lng == null) {
      _showError("Select address on map");
      return;
    }
    if (role.isEmpty) {
      _showError("Please select a role (User or Technician)");
      return;
    }
    if (role == 'technician') {
      if (selectedClinicId == null) {
        _showError("Select a clinic");
        return;
      }
      if (experienceController.text.trim().isEmpty) {
        _showError("Enter years of experience");
        return;
      }
      if (documentLinkController.text.trim().isEmpty) {
        _showError("Provide document link (Google Drive, etc.)");
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      Map<String, dynamic> updateData = {
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(), // now editable
        'lat': lat,
        'lng': lng,
        'profileCompleted': true,
        'role': role,
      };

      if (role == 'technician') {
        updateData.addAll({
          'clinicId': selectedClinicId,
          'clinicName': selectedClinicName,
          'clinicAddress': selectedClinicAddress,
          'experience': experienceController.text.trim(),
          'documentUrl': documentLinkController.text.trim(),
          'verified': false,
        });
      } else {
        updateData.addAll({
          'verified': true,
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleRedirect()),
        );
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "Almost there 👋",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Complete your profile to continue",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // Role selector (only if role not already set)
            if (role.isEmpty) ...[
              const Text("I am a", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              RoleSelector(
                role: "user",
                onChanged: (value) {
                  setState(() => role = value);
                },
              ),
              const SizedBox(height: 20),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "You are registering as: ${role.toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),

            // Phone field
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Phone Number *",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Location picker
            ElevatedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map),
              label: const Text("Select Address on Map"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            // 🔁 Address field – now editable
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Enter full address or select from map *",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Technician specific fields
            if (role == 'technician') ...[
              const Text("Clinic *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (isLoadingClinics)
                const Center(child: CircularProgressIndicator())
              else if (clinicError != null)
                Column(
                  children: [
                    Text(clinicError!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadClinics,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedClinicId,
                  hint: const Text("Select a clinic"),
                  isExpanded: true,
                  items: clinics.map((clinic) {
                    return DropdownMenuItem<String>(
                      value: clinic['id'],
                      child: Text(clinic['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClinicId = value;
                      final clinic = clinics.firstWhere((c) => c['id'] == value);
                      selectedClinicName = clinic['name'];
                      selectedClinicAddress = clinic['address'];
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 16),

              TextField(
                controller: experienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Experience (Years) *",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: documentLinkController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: "Document Link (Google Drive, Dropbox) *",
                  helperText: "Link to your license or certificate",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Continue",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}