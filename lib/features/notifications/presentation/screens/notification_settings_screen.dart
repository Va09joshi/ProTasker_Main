import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_preferences.dart';
import '../widgets/permission_dialog.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _osPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkOsPermission();
  }

  Future<void> _checkOsPermission() async {
    final granted = await FcmNotificationService.checkPermissionStatus();
    setState(() {
      _osPermissionGranted = granted;
    });
  }

  Future<void> _requestPermission() async {
    final result = await NotificationPermissionDialog.show(context);
    if (result == true) {
      _checkOsPermission();
      // If granted, we should probably toggle globalEnabled if it was false
      final currentPrefs = ref.read(notificationSettingsProvider).value;
      if (currentPrefs != null && !currentPrefs.globalEnabled) {
        ref.read(notificationSettingsProvider.notifier).updatePreferences(
              currentPrefs.copyWith(globalEnabled: true),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
      ),
      body: preferencesAsync.when(
        data: (preferences) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_osPermissionGranted)
                _buildPermissionWarning(),
                
              _buildMainToggle(preferences),
              const SizedBox(height: 24),
              
              if (preferences.globalEnabled) ...[
                _buildSectionHeader('Updates & Alerts'),
                _buildToggleCard([
                  _buildSwitchTile(
                    'Chat Messages',
                    'New messages from providers or support',
                    preferences.chat,
                    (v) => _updatePrefs(preferences.copyWith(chat: v)),
                  ),
                  _buildSwitchTile(
                    'Booking Updates',
                    'Status changes for your bookings',
                    preferences.bookings,
                    (v) => _updatePrefs(preferences.copyWith(bookings: v)),
                  ),
                  _buildSwitchTile(
                    'Provider Accepted',
                    'When a provider accepts your job',
                    preferences.providerAccepted,
                    (v) => _updatePrefs(preferences.copyWith(providerAccepted: v)),
                  ),
                  _buildSwitchTile(
                    'Provider Arrived',
                    'When a provider arrives at location',
                    preferences.providerArrived,
                    (v) => _updatePrefs(preferences.copyWith(providerArrived: v)),
                  ),
                  _buildSwitchTile(
                    'Service Started',
                    'When your job begins',
                    preferences.serviceStarted,
                    (v) => _updatePrefs(preferences.copyWith(serviceStarted: v)),
                  ),
                  _buildSwitchTile(
                    'Service Completed',
                    'When your job is finished',
                    preferences.serviceCompleted,
                    (v) => _updatePrefs(preferences.copyWith(serviceCompleted: v)),
                  ),
                  _buildSwitchTile(
                    'Payment Updates',
                    'Receipts and payment status',
                    preferences.payments,
                    (v) => _updatePrefs(preferences.copyWith(payments: v)),
                    isLast: true,
                  ),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionHeader('News & Offers'),
                _buildToggleCard([
                  _buildSwitchTile(
                    'Promotions',
                    'Discounts and special offers',
                    preferences.promotions,
                    (v) => _updatePrefs(preferences.copyWith(promotions: v)),
                  ),
                  _buildSwitchTile(
                    'Announcements',
                    'New features and updates',
                    preferences.announcements,
                    (v) => _updatePrefs(preferences.copyWith(announcements: v)),
                  ),
                  _buildSwitchTile(
                    'Marketing',
                    'Tips and partner offers',
                    preferences.marketing,
                    (v) => _updatePrefs(preferences.copyWith(marketing: v)),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),
                _buildSectionHeader('Advanced Settings'),
                _buildToggleCard([
                  _buildSwitchTile(
                    'Quiet Hours',
                    'Mute notifications from \${preferences.quietHoursStart} to \${preferences.quietHoursEnd}',
                    preferences.quietHoursEnabled,
                    (v) => _updatePrefs(preferences.copyWith(quietHoursEnabled: v)),
                  ),
                  _buildSwitchTile(
                    'Sound',
                    'Play a sound for notifications',
                    preferences.soundEnabled,
                    (v) => _updatePrefs(preferences.copyWith(soundEnabled: v)),
                  ),
                  _buildSwitchTile(
                    'Vibration',
                    'Vibrate for notifications',
                    preferences.vibrationEnabled,
                    (v) => _updatePrefs(preferences.copyWith(vibrationEnabled: v)),
                  ),
                  _buildSwitchTile(
                    'Badge Count',
                    'Show unread count on app icon',
                    preferences.badgeCountEnabled,
                    (v) => _updatePrefs(preferences.copyWith(badgeCountEnabled: v)),
                    isLast: true,
                  ),
                ]),
              ]
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _updatePrefs(NotificationPreferences newPrefs) {
    ref.read(notificationSettingsProvider.notifier).updatePreferences(newPrefs);
  }

  Widget _buildPermissionWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications are disabled in your device settings.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _requestPermission,
            child: const Text('Enable'),
          )
        ],
      ),
    );
  }

  Widget _buildMainToggle(NotificationPreferences preferences) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: preferences.globalEnabled ? AppColors.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              preferences.globalEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: preferences.globalEnabled ? AppColors.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: preferences.globalEnabled ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  preferences.globalEnabled ? 'On' : 'Off',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: preferences.globalEnabled ? Colors.white70 : Colors.black54,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: preferences.globalEnabled,
            onChanged: (value) async {
              if (value && !_osPermissionGranted) {
                await _requestPermission();
              } else {
                _updatePrefs(preferences.copyWith(globalEnabled: value));
              }
            },
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary.withOpacity(0.5),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildToggleCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey[200],
          ),
      ],
    );
  }
}
