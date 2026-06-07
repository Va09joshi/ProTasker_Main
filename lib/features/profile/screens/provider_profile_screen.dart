import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../location/screens/map_picker_screen.dart';
import '../../../core/router/route_names.dart';
import '../providers/profile_providers.dart';
import '../providers/provider_profile_providers.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';


class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _expCtrl;
  
  List<String> _serviceAreas = [];
  List<String> _offeredServices = [];
  List<String> _portfolioUrls = [];
  Map<String, dynamic> _schedule = {};

  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  UserModel? _initializedUser;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _expCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  void _initDataIfNeeded(UserModel user) {
    if (_initializedUser?.uid == user.uid) return;
    _initializedUser = user;
    
    _nameCtrl.text = user.name;
    _phoneCtrl.text = user.phone;
    _bioCtrl.text = user.bio ?? '';
    _expCtrl.text = user.experienceYears ?? '';
    _serviceAreas = List.from(user.serviceAreas ?? []);
    _offeredServices = List.from(user.offeredServices ?? []);
    _portfolioUrls = List.from(user.portfolioImages ?? []);
    
    _schedule = Map<String, dynamic>.from(user.availabilitySchedule ?? {});
    if (_schedule.isEmpty) {
      for (var day in _daysOfWeek) {
        if (_schedule[day] == null) {
          _schedule[day] = {'enabled': false, 'start': '09:00', 'end': '17:00'};
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_initializedUser == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_initializedUser!.uid).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'experienceYears': _expCtrl.text.trim(),
        'serviceAreas': _serviceAreas,
        'offeredServices': _offeredServices,
        'portfolioImages': _portfolioUrls,
        'availabilitySchedule': _schedule,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      if (mounted) SnackbarHelper.success(context, 'Profile updated successfully');
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) SnackbarHelper.error(context, 'Error: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    if (_initializedUser == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    setState(() => _isSaving = true);
    try {
      final url = await CloudinaryService.uploadFile(File(file.path));
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(_initializedUser!.uid).update({'profilePhoto': url});
      } else {
        throw Exception('Upload returned null URL');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.error(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadPortfolioImage() async {
    if (_initializedUser == null || _portfolioUrls.length >= 10) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    setState(() => _isSaving = true);
    try {
      final url = await CloudinaryService.uploadFile(File(file.path));
      if (url == null) throw Exception('Upload returned null URL');
      setState(() {
        _portfolioUrls.add(url);
        _isSaving = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.error(context, 'Upload failed: $e');
      }
    }
  }

  Future<void> _pickTime(String day, String field) async {
    final current = _schedule[day]?[field] ?? '09:00';
    final parts = current.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      setState(() {
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        _schedule[day]![field] = '$hh:$mm';
      });
    }
  }

  void _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'Logout',
        message: 'Are you sure you want to logout from your provider account?',
        confirmLabel: 'Logout',
        isDanger: true,
      ),
    );

    if (confirm == true) {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return RoleGuard.provider(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          scrolledUnderElevation: 0,
          actions: [
            if (_isEditing)
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _isEditing = false))
            else
              IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => setState(() => _isEditing = true)),
          ],
        ),
        body: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text('User not found'));
            _initDataIfNeeded(user);
            
            return SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: 100,
                      left: MediaQuery.of(context).size.width > 600 ? 32.0 : 0.0,
                      right: MediaQuery.of(context).size.width > 600 ? 32.0 : 0.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(user),
                        const SizedBox(height: AppDimensions.paddingLG),
                        _buildStatsRow(user),
                        const SizedBox(height: AppDimensions.paddingXL),
                        _buildPersonalInfo(),
                        const Divider(height: 48, color: AppColors.border),
                        _buildServiceDetails(),
                        const Divider(height: 48, color: AppColors.border),
                        _buildPortfolio(),
                        const Divider(height: 48, color: AppColors.border),
                        _buildSchedule(),
                        const Divider(height: 48, color: AppColors.border),
                        _buildAccountSettings(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingLG),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
                          boxShadow: [
                            BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))
                          ],
                        ),
                        child: AppButton(
                          label: 'Save Changes',
                          onPressed: _saveProfile,
                          isLoading: _isSaving,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.profile),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(currentUserProvider)),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingMD),
      child: Column(
        children: [
          Stack(
            children: [
              AppAvatar(
                name: user.name,
                imageUrl: user.profilePhoto,
                size: 100,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isSaving ? null : _uploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
          const SizedBox(height: AppDimensions.paddingLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.name, style: AppTextStyles.displayMedium),
              if (user.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: AppColors.info, size: 22),
              ]
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 4),
              Text('${user.rating.toStringAsFixed(1)} (${user.totalJobs} jobs)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserModel user) {
    final statsAsync = ref.watch(providerProfileStatsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
        ),
        child: statsAsync.when(
          data: (stats) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Rating', user.rating.toStringAsFixed(1)),
              _buildStatItem('Jobs', '${user.totalJobs}'),
              _buildStatItem('Completion', '${stats.completionRate.toStringAsFixed(0)}%'),
              _buildStatItem('Response', stats.avgResponseTime),
            ],
          ),
          loading: () => const LoadingShimmer(type: ShimmerType.card),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerProfileStatsProvider)),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingLG),
          AppTextField(
            label: 'Full Name',
            controller: _nameCtrl,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          AppTextField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          AppTextField(
            label: 'Email Address',
            controller: TextEditingController(text: _initializedUser?.email ?? ''),
            enabled: false,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          AppTextField(
            label: 'Bio',
            controller: _bioCtrl,
            enabled: _isEditing,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Details', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingLG),
          AppTextField(
            label: 'Years of Experience',
            controller: _expCtrl,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          
          const Text('Categories Offered', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.paddingSM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ServiceCategory.values.map((cat) {
              final isSelected = _offeredServices.contains(cat.name);
              return FilterChip(
                label: Text(cat.name, style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
                selected: isSelected,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.accent.withValues(alpha: 0.1),
                checkmarkColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                onSelected: _isEditing ? (val) {
                  setState(() {
                    if (val) _offeredServices.add(cat.name);
                    else _offeredServices.remove(cat.name);
                  });
                } : null,
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          
          const Text('Service Areas (Cities)', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.paddingSM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._serviceAreas.map((city) => Chip(
                label: Text(city),
                backgroundColor: AppColors.surfaceAlt,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
                deleteIconColor: AppColors.textSecondary,
                onDeleted: _isEditing ? () => setState(() => _serviceAreas.remove(city)) : null,
              )),
              if (_isEditing)
                ActionChip(
                  label: const Text('+ Add Area'),
                  backgroundColor: AppColors.background,
                  side: const BorderSide(color: AppColors.accent),
                  labelStyle: const TextStyle(color: AppColors.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
                  onPressed: () async {
                    final result = await context.pushNamed(RouteNames.mapPicker);
                    if (result != null && result is MapPickerResult) {
                      final String city = result.placemark.locality ?? 
                                          result.placemark.subAdministrativeArea ?? 
                                          result.placemark.administrativeArea ?? 
                                          '';
                      if (city.isNotEmpty && !_serviceAreas.contains(city)) {
                        setState(() => _serviceAreas.add(city));
                      } else if (city.isEmpty && mounted) {
                        SnackbarHelper.error(context, 'Could not determine city from selected location.');
                      } else if (_serviceAreas.contains(city) && mounted) {
                        SnackbarHelper.error(context, '$city is already in your service areas.');
                      }
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Portfolio Images', style: AppTextStyles.headingLarge),
              Text('${_portfolioUrls.length}/10', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          if (_portfolioUrls.isEmpty && !_isEditing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLG), border: Border.all(color: AppColors.border)),
              child: const Text('No portfolio images added yet.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: _isEditing && _portfolioUrls.length < 10 ? _portfolioUrls.length + 1 : _portfolioUrls.length,
              itemBuilder: (context, index) {
                if (_isEditing && index == _portfolioUrls.length) {
                  return GestureDetector(
                    onTap: _isSaving ? null : _uploadPortfolioImage,
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.textSecondary, size: 28),
                          SizedBox(height: 4),
                          Text('Add', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      child: CachedNetworkImage(imageUrl: _portfolioUrls[index], fit: BoxFit.cover),
                    ),
                    if (_isEditing)
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _portfolioUrls.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.7), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.background),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Availability Schedule', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingLG),
          ..._daysOfWeek.map((day) {
            final data = _schedule[day] as Map<String, dynamic>? ?? {'enabled': false, 'start': '09:00', 'end': '17:00'};
            final isEnabled = data['enabled'] == true;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Row(
                      children: [
                        Checkbox(
                          value: isEnabled,
                          activeColor: AppColors.accent,
                          onChanged: _isEditing ? (val) => setState(() => _schedule[day]!['enabled'] = val) : null,
                        ),
                        Expanded(child: Text(day.substring(0, 3), style: AppTextStyles.bodyMedium.copyWith(fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal))),
                      ],
                    ),
                  ),
                  if (isEnabled) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: _isEditing ? () => _pickTime(day, 'start') : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
                          child: Text(data['start'], textAlign: TextAlign.center, style: AppTextStyles.labelLarge),
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text('-', style: TextStyle(color: AppColors.textSecondary))),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isEditing ? () => _pickTime(day, 'end') : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
                          child: Text(data['end'], textAlign: TextAlign.center, style: AppTextStyles.labelLarge),
                        ),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
                        child: const Text('Closed', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    final notifs = ref.watch(notificationsEnabledProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          child: Text('Account Settings', style: AppTextStyles.headingLarge),
        ),
        const SizedBox(height: AppDimensions.paddingLG),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                secondary: const Icon(Icons.notifications_rounded, color: AppColors.textSecondary),
                value: notifs,
                activeColor: AppColors.accent,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG))),
                onChanged: (val) {
                  ref.read(notificationsEnabledProvider.notifier).toggle(val);
                },
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.textSecondary),
                value: isDark,
                activeColor: AppColors.accent,
                onChanged: null, // Temporarily disabled
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.account_balance_rounded, color: AppColors.textSecondary),
                title: const Text('Bank Details'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Coming Soon', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                onTap: () => context.push('/help-center'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusLG))),
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
