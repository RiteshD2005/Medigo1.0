import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart';
import '../home/role_redirect.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const RoleRedirect(); // your home logic
    } else {
      return LoginScreen();
    }
  }
}