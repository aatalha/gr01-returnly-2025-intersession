import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:returnly/auth/login_screen.dart';
import 'package:returnly/main.dart'; 

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return TestHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}