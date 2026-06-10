import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.protasker/pusher');
  static const String _instanceId = 'ae015999-12be-4b38-bdbc-15ad30dfd991';
  static bool _pushDiagnosticsInitialized = false;

  static Future<void> initializePushDiagnostics() async {
    if (_pushDiagnosticsInitialized) return;
    _pushDiagnosticsInitialized = true;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM TOKEN: $token');
      if (token == null) {
        debugPrint('FCM token is null. Notifications will never arrive.');
      }

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground message received');
        debugPrint(message.notification?.title);
        debugPrint(message.notification?.body);
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((refreshedToken) {
        debugPrint('FCM TOKEN REFRESHED: $refreshedToken');
      });
    } catch (e) {
      debugPrint('Failed to initialize push diagnostics: $e');
    }
  }

  /// Call this when the user logs in to subscribe their device to their unique ID
  static Future<void> subscribeToUser(String uid) async {
    try {
      final interest = 'user-$uid';
      await _channel.invokeMethod('setInterest', {'interest': interest});
      debugPrint('Subscribed to $interest');
    } catch (e) {
      debugPrint('Failed to subscribe to pusher interest: $e');
    }
  }

  /// Call this when the user logs out
  static Future<void> clearSubscriptions() async {
    try {
      await _channel.invokeMethod('clearInterests');
      debugPrint('Cleared Pusher interests');
    } catch (e) {
      debugPrint('Failed to clear pusher interests: $e');
    }
  }

  /// Sends a push notification to a specific user using Pusher Beams Publish API
  static Future<void> sendNotification({
    required String targetUid,
    required String title,
    required String body,
  }) async {
    try {
      final secretKey = dotenv.env['PUSHER_BEAMS_SECRET_KEY'];
      
      if (secretKey == null || secretKey.isEmpty || secretKey == 'YOUR_PUSHER_SECRET_KEY_HERE') {
        debugPrint('WARNING: PUSHER_BEAMS_SECRET_KEY is not set in .env file. Notification will not be sent.');
        return;
      }

      final url = Uri.parse('https://$_instanceId.pushnotifications.pusher.com/publish_api/v1/instances/$_instanceId/publishes');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secretKey',
        },
        body: jsonEncode({
          'interests': ['user-$targetUid'],
          'fcm': {
            'notification': {
              'title': title,
              'body': body,
            }
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
