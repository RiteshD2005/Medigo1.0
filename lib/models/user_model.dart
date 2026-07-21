class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String address;
  final double? lat;
  final double? lng;
  final bool verified;
  final bool profileCompleted;

  // Technician-specific fields
  final String? clinicId;
  final String? clinicName;
  final String? clinicAddress;
  final String? experience;
  final String? documentUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.address,
    this.lat,
    this.lng,
    required this.verified,
    required this.profileCompleted,
    this.clinicId,
    this.clinicName,
    this.clinicAddress,
    this.experience,
    this.documentUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'lat': lat,
      'lng': lng,
      'verified': verified,
      'profileCompleted': profileCompleted,
      'clinicId': clinicId,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'experience': experience,
      'documentUrl': documentUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      verified: map['verified'] ?? false,
      profileCompleted: map['profileCompleted'] ?? false,
      clinicId: map['clinicId'],
      clinicName: map['clinicName'],
      clinicAddress: map['clinicAddress'],
      experience: map['experience'],
      documentUrl: map['documentUrl'],
    );
  }
}