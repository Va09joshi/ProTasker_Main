import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

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
      // await _channel.invokeMethod('setInterest', {'interest': interest});
      debugPrint('Subscribed to $interest');
    } catch (e) {
      debugPrint('Failed to subscribe to pusher interest: $e');
    }
  }

  /// Call this when the user logs out
  static Future<void> clearSubscriptions() async {
    try {
      // await _channel.invokeMethod('clearInterests');
      debugPrint('Cleared Pusher interests');
    } catch (e) {
      debugPrint('Failed to clear pusher interests: $e');
    }
  }

  /// Sends a push notification directly from the client using FCM HTTP v1 API
  static Future<void> sendNotification({
    required String targetUid,
    required String title,
    required String body,
  }) async {
    try {
      // 1. Fetch the target user's FCM Token from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(targetUid).get();
      if (!userDoc.exists) {
        debugPrint('Target user not found');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('Target user has no FCM token. Cannot send push notification.');
        return;
      }

      // 2. Load the Service Account from assets and get OAuth2 Token
      String serviceAccountJson;
      try {
        serviceAccountJson = await rootBundle.loadString('assets/service_account.json');
      } catch (e) {
        debugPrint('WARNING: assets/service_account.json not found! Cannot send FCM push.');
        return;
      }

      final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      final accessToken = client.credentials.accessToken.data;
      client.close();

      // 3. Send the POST Request to FCM
      final projectId = 'protasker-3bf46';
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('Successfully sent push notification to $targetUid');
      } else {
        debugPrint('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
