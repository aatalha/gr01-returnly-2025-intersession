import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:returnly_app/screens/auth/login_screen.dart';
import 'package:returnly_app/screens/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      // If user IDs are Firestore doc IDs:
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      // If using a 'uid' field in your documents instead of doc IDs:
      // final snap = await FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: uid).limit(1).get();
      // if (snap.docs.isNotEmpty) {
      //   return snap.docs.first.data();
      // }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          // Here you can use a FutureBuilder if you want to fetch user profile from Firestore:
          return FutureBuilder<Map<String, dynamic>?>(
            future: fetchUserProfile(user.uid),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (profileSnap.hasError) {
                return Center(child: Text('Error loading profile'));
              }
              // Pass the profile data to your HomeScreen if needed
              // You could also create a user model from profileSnap.data if you want
              return HomeScreen(user: user);
            },
          );
        }

        // User is NOT logged in
        return const LoginScreen();
      },
    );
  }
}
