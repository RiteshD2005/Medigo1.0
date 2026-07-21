import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/user_home.dart';
import '../technician/technician_home.dart';
import '../auth/complete_profile_screen.dart';

class RoleRedirect extends StatelessWidget {
  const RoleRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return FutureBuilder(
      future: auth.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          // Error → go back to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
          });
          return const Scaffold(body: Center(child: Text("Error loading profile")));
        }
        final user = snapshot.data!;
        // Check profile completion
        if (user.profileCompleted != true) {
          return const CompleteProfileScreen();
        }
        // Role-based navigation
        if (user.role == "user") {
          return const UserHome();
        } else {
          return const TechnicianHome();
        }
      },
    );
  }
}