import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermission();

    // Get and store FCM token
    await _getAndStoreFCMToken();

    // Set up foreground message handler
    _setupForegroundMessageHandler();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps when app is opened from background
    _setupNotificationTapHandler();

    // Set up notification presentation options for iOS
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permission: $e');
      }
    }
  }

  static Future<void> _getAndStoreFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        await _storeFCMTokenInFirestore(token);
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        _storeFCMTokenInFirestore(newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  static Future<void> _storeFCMTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing FCM token: $e');
      }
    }
  }

  static void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      }

      // Handle the message here - you could show a local notification
      // or update the UI directly
      _handleForegroundMessage(message);
    });
  }

  static void _setupNotificationTapHandler() {
    // Handle notification taps when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
        print('Message data: ${message.data}');
      }
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state by tapping notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App opened from terminated state via notification');
          print('Message data: ${message.data}');
        }
        _handleNotificationTap(message);
      }
    });
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // In a real app, you might want to show a local notification here
    // or update some UI state to indicate a new message has arrived

    // For now, we'll just log it
    if (message.notification != null) {
      if (kDebugMode) {
        print('Foreground notification: ${message.notification!.title}');
        print('Body: ${message.notification!.body}');
      }
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation when user taps on notification
    // You could navigate to a specific screen based on the message data

    if (kDebugMode) {
      print('User tapped on notification');
      print('Message data: ${message.data}');
    }

    // Example: Navigate to chat if it's a chat message
    if (message.data['type'] == 'chat') {
      final chatId = message.data['chatId'];
      if (chatId != null) {
        // Navigate to chat screen
        // This would need to be implemented based on your navigation setup
        if (kDebugMode) {
          print('Should navigate to chat: $chatId');
        }
      }
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        // In a real app, you would send this to your backend server
        // which would then use the Firebase Admin SDK to send the notification

        if (kDebugMode) {
          print('Would send notification to token: $fcmToken');
          print('Title: $title');
          print('Body: $body');
          print('Data: $data');
        }

        // For testing, you can use the Firebase Console to send notifications
        // or implement a Cloud Function to handle this
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  // Send notification when new message is received
  static Future<void> sendChatNotification({
    required String receiverUserId,
    required String senderName,
    required String itemTitle,
    required String message,
    required String chatId,
  }) async {
    await sendNotificationToUser(
      userId: receiverUserId,
      title: '$senderName sent a message',
      body: 'About: $itemTitle - $message',
      data: {
        'type': 'chat',
        'chatId': chatId,
        'senderName': senderName,
        'itemTitle': itemTitle,
      },
    );
  }

  // Send notification for high priority items
  static Future<void> sendHighPriorityItemNotification({
    required String title,
    required String location,
    required String category,
    required String postId,
  }) async {
    // This would typically be sent to all users or users in the vicinity
    // For now, we'll just log it
    if (kDebugMode) {
      print('Would send high priority notification:');
      print('Title: ⚠️ High Priority Item Found: $title');
      print('Body: $category found at $location. Check it out!');
      print('PostId: $postId');
    }
  }

  // Clean up FCM token when user logs out
  static Future<void> clearFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing FCM token: $e');
      }
    }
  }
}

// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print('Message data: ${message.data}');
    if (message.notification != null) {
      print('Message notification: ${message.notification}');
    }
  }
}