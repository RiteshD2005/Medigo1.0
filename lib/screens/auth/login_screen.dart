import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart';
import '../home/role_redirect.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 40),

              Text(
                "Medigo",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              Text(
                "Book Home Medical Tests Easily",
                style: TextStyle(
                    color: Colors.grey
                ),
              ),

              SizedBox(height: 40),

              TextField(
                controller: email,
                decoration: InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                  ),
                ),
              ),

              SizedBox(height: 20),

              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                  ),
                ),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {

                    try {

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      await auth.login(
                        email.text,
                        password.text,
                      );

                      Navigator.pop(context);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoleRedirect(),
                        ),
                      );

                    } catch (e) {

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );

                    }

                  },
                  child: Text("Login"),
                ),
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () async {

                    try {

                      await auth.googleLogin();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoleRedirect(),
                        ),
                      );

                    } catch (e) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );

                    }

                  },
                  icon: Icon(Icons.g_mobiledata, size: 30),
                  label: Text("Continue with Google"),
                ),
              ),

              SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(),
                      ),
                    );

                  },
                  child: Text("Create Account"),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}