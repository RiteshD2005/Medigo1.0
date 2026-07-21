import 'package:flutter/material.dart';
import '../../widgets/role_selector.dart';
import '../../services/auth_service.dart';
import '../location/location_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String role = "user";
  double? lat;
  double? lng;

  // Document link instead of file
  final TextEditingController documentLinkController = TextEditingController();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final experienceController = TextEditingController();

  final auth = AuthService();

  List<Map<String, dynamic>> clinics = [];
  String? selectedClinicId;
  String? selectedClinicName;
  String? selectedClinicAddress;
  bool isLoadingClinics = true;
  String? clinicError;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _experienceFocus = FocusNode();
  final FocusNode _documentLinkFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    addressController.dispose();
    experienceController.dispose();
    documentLinkController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _addressFocus.dispose();
    _experienceFocus.dispose();
    _documentLinkFocus.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading clinics: ${e.toString()}")),
      );
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
        // If LocationPicker returns an address, use it; otherwise user types manually
        if (result['address'] != null && result['address'].toString().isNotEmpty) {
          addressController.text = result['address'];
        }
      });
    }
  }

  // Validators
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (value.trim().length < 10) return 'Enter a valid phone number (min 10 digits)';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    return null;
  }

  String? _validateExperience(String? value) {
    if (role != 'technician') return null;
    if (value == null || value.trim().isEmpty) return 'Experience is required';
    final exp = int.tryParse(value.trim());
    if (exp == null || exp < 0) return 'Enter a valid number of years';
    return null;
  }

  String? _validateDocumentLink(String? value) {
    if (role != 'technician') return null;
    if (value == null || value.trim().isEmpty) {
      return 'Document link is required (Google Drive, Dropbox, etc.)';
    }
    // Basic URL validation
    if (!value.trim().startsWith('http://') && !value.trim().startsWith('https://')) {
      return 'Enter a valid URL starting with http:// or https://';
    }
    return null;
  }

  String? _validateLocation() {
    if (lat == null || lng == null) return 'Please select your location on the map';
    return null;
  }

  Future<void> _register() async {
    // 1️⃣ Form validation
    if (!_formKey.currentState!.validate()) return;

    // 2️⃣ Location validation
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location on the map'), backgroundColor: Colors.red),
      );
      return;
    }

    // 3️⃣ Technician specific validations
    if (role == 'technician') {
      if (selectedClinicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a clinic'), backgroundColor: Colors.red),
        );
        return;
      }
      if (documentLinkController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a document link'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // 4️⃣ Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 5️⃣ Call AuthService.register with all required parameters
      await auth.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: role,
        phone: phoneController.text.trim(),
        address: addressController.text.trim(), // ✅ uses the text field
        lat: lat!,
        lng: lng!,
        clinicId: selectedClinicId,
        clinicName: selectedClinicName,
        clinicAddress: selectedClinicAddress,
        experience: experienceController.text.trim(),
        documentUrl: role == 'technician' ? documentLinkController.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful!')),
        );
        Navigator.pop(context); // go back to login
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // dismiss loading
      if (mounted) {
        String errorMsg = e.toString();
        // Friendly error messages
        if (errorMsg.contains('email-already-in-use')) {
          errorMsg = 'Email already in use. Please login or use another email.';
        } else if (errorMsg.contains('network')) {
          errorMsg = 'Network error. Check your internet connection.';
        } else if (errorMsg.contains('UNAVAILABLE')) {
          errorMsg = 'Firestore connection failed. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Create Account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Full Name
              TextFormField(
                controller: nameController,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Full Name *",
                  hintText: "John Doe",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validateName,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: emailController,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email *",
                  hintText: "you@example.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocus),
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: phoneController,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone *",
                  hintText: "9876543210",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validatePhone,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: passwordController,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.next,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password *",
                  hintText: "••••••",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 20),

              // Location picker
              const Text(
                "Your Location *",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map),
                      label: const Text("Pick Location on Map"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              if (lat == null || lng == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Location is required",
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          addressController.text.isNotEmpty
                              ? addressController.text
                              : "Location selected (tap to change)",
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Address text field (full address)
              TextFormField(
                controller: addressController,
                focusNode: _addressFocus,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Full Address *",
                  hintText: "House no, street, city, pincode",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? "Address is required" : null,
              ),
              const SizedBox(height: 24),

              // Role selector
              const Text(
                "Register As",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RoleSelector(
                role: role,
                onChanged: (value) {
                  setState(() {
                    role = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Technician specific fields
              if (role == "technician") ...[
                const Text(
                  "Clinic Association *",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
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
                    validator: (_) {
                      if (selectedClinicId == null) return "Please select a clinic";
                      return null;
                    },
                  ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: experienceController,
                  focusNode: _experienceFocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Experience (Years) *",
                    hintText: "e.g., 5",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _validateExperience,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_documentLinkFocus),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: documentLinkController,
                  focusNode: _documentLinkFocus,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: "License Document Link *",
                    hintText: "https://drive.google.com/...",
                    helperText: "Google Drive, Dropbox, or any cloud storage link",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _validateDocumentLink,
                  onFieldSubmitted: (_) => _register(),
                ),
                const SizedBox(height: 24),
              ],

              // Register button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Register", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}