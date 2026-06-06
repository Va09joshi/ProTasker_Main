import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../../shared/models/models.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize(String? currentUserId) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handlePayload(jsonDecode(response.payload!));
        }
      },
    );

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (currentUserId != null) {
        final token = await _fcm.getToken();
        if (token != null) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({'fcmToken': token});
          } catch (_) {}
        }
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.data.isNotEmpty) {
          _handlePayload(message.data);
        }
      });

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        Future.delayed(const Duration(seconds: 1), () {
          _handlePayload(initialMessage.data);
        });
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'protasker_channel',
      'ProTasker Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _handlePayload(Map<String, dynamic> payload) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final typeStr = payload['type'] as String?;
    final bookingId = payload['bookingId'] as String?;
    final chatId = payload['chatId'] as String?;

    if (typeStr == NotificationType.newMessage.name && chatId != null) {
      context.push('/chat/$chatId');
    } else if (bookingId != null && 
        (typeStr == NotificationType.bookingRequest.name || 
         typeStr == NotificationType.bookingAccepted.name || 
         typeStr == NotificationType.bookingCompleted.name)) {
      context.push('/booking/$bookingId');
    } else {
      context.push('/notifications');
    }
  }
}
