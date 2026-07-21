import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // =========================
  // REGISTER (EMAIL)
  // =========================
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String address,
    required double lat,
    required double lng,

    // technician fields
    String? clinicId,
    String? clinicName,
    String? clinicAddress,
    String? experience,
    String? documentUrl,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    Map<String, dynamic> userData = {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'lat': lat,
      'lng': lng,
      'createdAt': FieldValue.serverTimestamp(),

      // 🔥 IMPORTANT
      'profileCompleted': true,
    };

    if (role == "user") {
      userData.addAll({
        'verified': true,
      });
    }

    if (role == "technician") {
      userData.addAll({
        'clinicId': clinicId,
        'clinicName': clinicName,
        'experience': experience,
        'clinicAddress': clinicAddress,
        'documentUrl': documentUrl,
        'verified': false,
      });
    }

    await firestore.collection('users').doc(uid).set(userData);
  }

  // =========================
  // LOGIN (EMAIL)
  // =========================
  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // =========================
  // GOOGLE LOGIN
  // =========================
  Future<void> googleLogin() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    // Force account picker every time
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser =
    await googleSignIn.signIn();

    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred =
    await auth.signInWithCredential(credential);

    final uid = userCred.user!.uid;

    final doc = await firestore
        .collection("users")
        .doc(uid)
        .get();

    // 🔥 FIRST TIME GOOGLE USER
    if (!doc.exists) {
      await firestore.collection("users").doc(uid).set({
        "uid": uid,
        "name": userCred.user!.displayName ?? "",
        "email": userCred.user!.email ?? "",
        "role": "",
        "phone": "",
        "address": "",
        "lat": null,
        "lng": null,
        "verified": false,

        // 🔥 VERY IMPORTANT
        "profileCompleted": false,

        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  // =========================
  // GET CURRENT USER DATA
  // =========================
  Future<UserModel> getUser() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final doc =
    await firestore.collection("users").doc(user.uid).get();

    if (!doc.exists) {
      throw Exception("User document not found");
    }

    return UserModel.fromMap(doc.data()!);
  }

  // =========================
  // COMPLETE PROFILE (GOOGLE USERS)
  // =========================
  Future<void> completeProfile({
    required String phone,
    required String address,
    required double lat,
    required double lng,
  }) async {
    final user = auth.currentUser;

    if (user == null) return;

    await firestore.collection("users").doc(user.uid).update({
      "phone": phone,
      "address": address,
      "lat": lat,
      "lng": lng,
      "profileCompleted": true,
    });
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await auth.signOut();
  }
}