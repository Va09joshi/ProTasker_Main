import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_preferences.dart';

class NotificationSettingsNotifier extends AsyncNotifier<NotificationPreferences> {
  static const String _prefsKey = 'notification_preferences';

  @override
  Future<NotificationPreferences> build() async {
    return _loadPreferences();
  }

  Future<NotificationPreferences> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_prefsKey);
    
    NotificationPreferences preferences = const NotificationPreferences();
    
    if (cachedData != null) {
      try {
        preferences = NotificationPreferences.fromJson(cachedData);
      } catch (e) {
        // Fallback to default if corrupted
      }
    }

    // Try to sync with Firestore if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.containsKey('notificationPreferences')) {
             final prefsMap = Map<String, dynamic>.from(data['notificationPreferences'] as Map);
             final advancedMap = data.containsKey('notificationAdvanced') ? Map<String, dynamic>.from(data['notificationAdvanced'] as Map) : {};
             
             final Map<String, dynamic> mergedMap = {
               'globalEnabled': data['notificationEnabled'] ?? true,
               ...prefsMap,
               ...advancedMap
             };
             
             preferences = NotificationPreferences.fromMap(mergedMap);
             
             // Update local cache with fetched data
             await prefs.setString(_prefsKey, preferences.toJson());
          }
        }
      } catch (e) {
        // Ignore firestore fetch errors, just use local
      }
    }

    return preferences;
  }

  Future<void> updatePreferences(NotificationPreferences newPreferences) async {
    // Optimistic UI update
    state = AsyncData(newPreferences);

    try {
      // 1. Save to local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, newPreferences.toJson());

      // 2. Sync to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final map = newPreferences.toMap();
        
        final bool globalEnabled = map.remove('globalEnabled') as bool;
        
        final advancedKeys = [
          'quietHoursEnabled',
          'quietHoursStart',
          'quietHoursEnd',
          'soundEnabled',
          'vibrationEnabled',
          'badgeCountEnabled',
          'deliveryMode',
        ];
        
        final advancedMap = <String, dynamic>{};
        for (var key in advancedKeys) {
          advancedMap[key] = map.remove(key);
        }
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'notificationEnabled': globalEnabled,
          'notificationPreferences': map,
          'notificationAdvanced': advancedMap,
        }, SetOptions(merge: true));
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      // Rollback on failure
      final current = await _loadPreferences();
      state = AsyncData(current);
    }
  }

  // Toggle helpers
  Future<void> toggleGlobal(bool value) async {
    if (state.value == null) return;
    await updatePreferences(state.value!.copyWith(globalEnabled: value));
  }
}

final notificationSettingsProvider = AsyncNotifierProvider<NotificationSettingsNotifier, NotificationPreferences>(() {
  return NotificationSettingsNotifier();
});
