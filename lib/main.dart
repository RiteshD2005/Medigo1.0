import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/splash_Screen.dart';
import 'services/firebase_service.dart';
import 'screens/auth/AuthWrapper.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.init();

  runApp(const Medigo());
}

class Medigo extends StatelessWidget {
  const Medigo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Medigo",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}