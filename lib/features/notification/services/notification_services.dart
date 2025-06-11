import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> initNotifications() async {
    await _fcm.requestPermission();
    final String? fcmToken = await _fcm.getToken();

    if (fcmToken != null) {
      print("FCM Token: $fcmToken");
      await _saveTokenToDatabase(fcmToken);
    }

    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true)); 
  }
}