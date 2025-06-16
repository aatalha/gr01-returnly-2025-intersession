import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:returnly_app/screens/auth/login_screen.dart';
import 'package:returnly_app/screens/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFEFAF6),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF102C57),
              ),
            ),
          );
        }

        // Handle auth state errors
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        final user = snapshot.data;

        // User is authenticated
        if (user != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: fetchUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFFFEFAF6),
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF102C57),
                    ),
                  ),
                );
              }

              return HomeScreen(user: user);
            },
          );
        }

        // User is not authenticated
        return const LoginScreen();
      },
    );
  }
}