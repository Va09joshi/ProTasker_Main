import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class FcmNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    // Create the default channel that FCM uses in the manifest
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'protasker_channel', // id
      'ProTasker Notifications', // name
      description: 'Default channel for ProTasker notifications',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Listen to token refresh
    _isInitialized = true;
    await syncToken();
  }

  /// Syncs the FCM token to Firestore if permission is granted
  static Future<void> syncToken() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          await _updateTokenInFirestore(token);
          debugPrint('FCM TOKEN FETCHED AND SYNCED: $token');
        }
      } catch (e) {
        debugPrint('Failed to sync FCM token: $e');
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    
    // Show notification for android and iOS
    if (notification != null) {
      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'protasker_channel',
            'ProTasker Notifications',
            channelDescription: 'Default channel for ProTasker notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          )
        ),
      );
    }
  }

  static Future<bool> checkPermissionStatus() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      // Also request FCM permission which configures APNs on iOS
      await _messaging.requestPermission();
      
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
      return true;
    }
    return false;
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }
  
  static Future<void> removeTokenFromFirestore() async {
     final user = FirebaseAuth.instance.currentUser;
     if (user != null) {
       try {
         final token = await _messaging.getToken();
         if (token != null) {
           await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
             'fcmToken': FieldValue.delete(),
           }, SetOptions(merge: true));
         }
       } catch (e) {
         debugPrint('Error removing FCM token: $e');
       }
     }
  }
}
