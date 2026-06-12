import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../jobs/models/job_post.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/router/route_names.dart';
import '../../location/screens/map_picker_screen.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(notificationsEnabledProvider.notifier).toggle(prefs.getBool('notificationsEnabled') ?? true);
    ref.read(isDarkModeProvider.notifier).toggle(prefs.getBool('isDarkMode') ?? false);
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    ref.read(notificationsEnabledProvider.notifier).toggle(value);
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    ref.read(isDarkModeProvider.notifier).toggle(value);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return RoleGuard.client(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              onPressed: () => _confirmLogout(context, ref),
            )
          ],
        ),
        body: SafeArea(
          child: userAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: Text('User not found.'));
              }
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    _buildHeader(context, user),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _buildStatsRow(),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _buildMyPosts(context),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _buildSettingsList(context, user),
                    const SizedBox(height: AppDimensions.paddingXL),
                  ],
                ),
              );
            },
            loading: () => const LoadingShimmer(type: ShimmerType.profile),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(currentUserProvider)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Row(
        children: [
          Stack(
            children: [
              AppAvatar(
                name: user.name,
                imageUrl: user.profilePhoto,
                size: 80,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showEditProfileSheet(context, user),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingSM),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.background),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.paddingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.displayMedium),
                const SizedBox(height: 4),
                Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user.phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final statsAsync = ref.watch(clientStatsProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: statsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildStatItem('Total Bookings', stats.totalBookings.toString())),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _buildStatItem('Total Spent', '₹${stats.totalSpent.toStringAsFixed(2)}')),
          ],
        ),
        loading: () => const LoadingShimmer(type: ShimmerType.card),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(clientStatsProvider)),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMyPosts(BuildContext context) {
    final myPostsAsync = ref.watch(myJobPostsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Job Posts', style: AppTextStyles.headingMedium),
              GestureDetector(
                onTap: () => context.push('/my-jobs'),
                child: Text('View All', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSM),
        myPostsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                child: EmptyState(
                  title: 'No Posts Yet',
                  subtitle: 'You haven\'t posted any jobs. Need help? Post a problem!',
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
              itemCount: posts.length > 3 ? 3 : posts.length, // Show up to 3 recent posts
              separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.paddingMD),
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    side: BorderSide(color: AppColors.border, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingSM,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                              ),
                              child: Text(
                                post.category,
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd().format(post.createdAt),
                              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingSM),
                        Text(
                          post.title,
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (post.budget != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Budget: ₹${post.budget!.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: AppDimensions.paddingSM),
                        Text(
                          post.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.paddingMD),
                        const Divider(),
                        const SizedBox(height: AppDimensions.paddingSM),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: post.status == 'open' ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                              ),
                              child: Text(
                                post.status.toUpperCase(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: post.status == 'open' ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            AppButton(
                              label: 'Details',
                              variant: ButtonVariant.secondary,
                              fullWidth: false,
                              onPressed: () {
                                context.push('/job/${post.id}');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppDimensions.paddingLG),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
            child: ErrorView(
              message: 'Failed to load posts',
              onRetry: () => ref.refresh(myJobPostsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context, UserModel user) {
    final notifs = ref.watch(notificationsEnabledProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingSM),
          child: Text('Settings', style: AppTextStyles.headingMedium),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
                title: const Text('Saved Address'),
                subtitle: Text(
                  user.address.street.isNotEmpty 
                      ? '${user.address.street}, ${user.address.city}, ${user.address.state} ${user.address.pincode}'
                      : 'No address saved',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG))),
                onTap: () async {
                  final result = await context.pushNamed<dynamic>(RouteNames.mapPicker);
                  if (result != null && result is MapPickerResult) {
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'address': {
                          'street': result.placemark.street ?? '',
                          'city': result.placemark.locality ?? '',
                          'state': result.placemark.administrativeArea ?? '',
                          'pincode': result.placemark.postalCode ?? '',
                          'country': result.placemark.country ?? '',
                          'lat': result.latitude,
                          'lng': result.longitude,
                        }
                      });
                      if (context.mounted) {
                        SnackbarHelper.success(context, 'Address updated successfully');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        SnackbarHelper.error(context, 'Failed to update address: $e');
                      }
                    }
                  }
                },
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_rounded, color: AppColors.textSecondary),
                title: const Text('Push Notifications'),
                value: notifs,
                onChanged: _toggleNotifications,
                activeColor: AppColors.accent,
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.textSecondary),
                title: const Text('Dark Mode'),
                value: isDark,
                onChanged: null, // Temporarily disabled
                activeColor: AppColors.accent,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusLG))),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingLG),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingSM),
          child: Text('Support', style: AppTextStyles.headingMedium),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help, color: AppColors.textSecondary),
                title: Text('Help Center', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG))),
                onTap: () => context.push('/help-center'),
              ),
              const Divider(height: 1, indent: 56, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.textSecondary),
                title: Text('Rate the App', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: AppColors.textSecondary),
                title: Text('Privacy Policy', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusLG))),
                onTap: () => context.push('/privacy-policy'),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.paddingLG),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          child: AppButton(
            variant: ButtonVariant.text,
            label: 'Delete Account',
            onPressed: () => _confirmDeleteAccount(context, user.uid),
            icon: Icons.delete_outline_rounded,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showEditProfileSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG))),
      builder: (ctx) => _EditProfileSheet(user: user),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'Logout',
        message: 'Are you sure you want to logout from your account?',
        confirmLabel: 'Logout',
        isDanger: true,
      ),
    );

    if (confirm == true) {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'Delete Account',
        message: 'This action is irreversible. All your data will be permanently deleted.',
        confirmLabel: 'Delete',
        isDanger: true,
      ),
    );

    if (confirm == true) {
      // Stub delete logic
    }
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isUploading = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await CloudinaryService.uploadFile(File(file.path));
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({'profilePhoto': url});
      } else {
        throw Exception('Cloudinary upload failed');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.error(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      SnackbarHelper.error(context, 'Please fill in all fields');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackbarHelper.error(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppDimensions.paddingLG,
        right: AppDimensions.paddingLG,
        top: AppDimensions.paddingSM,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle(),
          const SizedBox(height: AppDimensions.paddingMD),
          const Text('Edit Profile', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingLG),
          Center(
            child: Stack(
              children: [
                AppAvatar(
                  name: widget.user.name,
                  imageUrl: widget.user.profilePhoto,
                  size: 80,
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _uploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingSM),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.background),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          AppTextField(
            controller: _nameCtrl,
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          AppTextField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            prefixIcon: const Icon(Icons.phone_outlined),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          AppButton(
            label: 'Save Changes',
            onPressed: _save,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
        ],
      ),
    );
  }
}
