import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../repositories/booking_repository.dart';

class DirectBookingScreen extends ConsumerStatefulWidget {
  final String providerId;
  final String? category;

  const DirectBookingScreen({
    super.key,
    required this.providerId,
    this.category,
  });

  @override
  ConsumerState<DirectBookingScreen> createState() => _DirectBookingScreenState();
}

class _DirectBookingScreenState extends ConsumerState<DirectBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController(text: '0'); // To be negotiated

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:00 AM - 11:00 AM';
  String? _selectedCategory;

  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];

  bool _isLoading = false;
  bool _isEmergency = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking(UserModel client, UserModel provider) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      SnackbarHelper.warning(context, 'Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double basePrice = double.tryParse(_priceController.text) ?? 0.0;
      final double priorityFee = _isEmergency ? 199.0 : 0.0;
      final double price = basePrice + priorityFee;
      final bookingId = const Uuid().v4();

      final booking = BookingModel(
        id: bookingId,
        clientId: client.uid,
        clientName: client.name,
        clientPhone: client.phone,
        clientPhoto: client.profilePhoto,
        providerId: provider.uid,
        providerName: provider.name,
        providerPhone: provider.phone,
        providerPhoto: provider.profilePhoto,
        serviceId: 'direct_booking', // No specific service ID
        serviceTitle: 'Direct Booking - $_selectedCategory',
        serviceCategory: ServiceCategory.values.firstWhere(
          (e) => e.name == _selectedCategory,
          orElse: () => ServiceCategory.other,
        ),
        scheduledAt: _selectedDate,
        timeSlot: _selectedTimeSlot,
        status: BookingStatus.pending, // Pending Provider Approval
        address: client.address, // Default to client's address
        grossPrice: price,
        platformFee: 0.0, // Neglected platform fee
        netPrice: price,
        notes: _notesController.text,
        proofImages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        otp: (Random().nextInt(9000) + 1000).toString(),
        isEmergency: _isEmergency,
        priorityFee: priorityFee,
      );

      await ref.read(bookingRepositoryProvider).createBooking(booking);

      // Notify the provider
      await NotificationService.sendNotification(
        targetUid: provider.uid,
        title: 'New Booking Request',
        body: '${client.name} has requested your services for ${booking.serviceCategory.name}.',
      );

      if (mounted) {
        context.pop();
        SnackbarHelper.success(context, 'Booking Request Sent! Provider will be notified.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.error(context, 'Failed to send booking request. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentUserProvider);
    // Fetch provider using nearbyProvidersProvider or a similar provider
    // Since we don't have a simple fetch provider by ID in providers, let's create a local fetch or use StreamProvider
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Book Provider', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: clientAsync.when(
        data: (client) {
          if (client == null) return const Center(child: Text('User not found'));

          // For simplicity, we use FutureBuilder to fetch the provider directly here
          // Alternatively, we could create a providerProfileProvider
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').doc(widget.providerId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingShimmer(type: ShimmerType.profile);
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Provider not found'));
              }

              final provider = UserModel.fromFirestore(snapshot.data!);

              // Ensure _selectedCategory is valid for this provider
              List<String> categories = provider.offeredServices ?? [];
              if (categories.isEmpty) categories = [ServiceCategory.other.name];
              if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
                _selectedCategory = categories.first;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider Info
                      // Provider Info Header
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingLG),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 3),
                              ),
                              child: AppAvatar(name: provider.name, imageUrl: provider.profilePhoto, size: 64),
                            ),
                            const SizedBox(width: AppDimensions.paddingLG),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(provider.name, style: AppTextStyles.headingLarge),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${provider.rating.toStringAsFixed(1)} (${provider.totalReviews})', 
                                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),

                      const Text('Booking Details', style: AppTextStyles.headingLarge),
                      const SizedBox(height: AppDimensions.paddingLG),

                      // Service Category
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                          boxShadow: [
                            BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppDimensions.paddingMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.category_rounded, color: AppColors.accent, size: 20),
                                const SizedBox(width: 8),
                                const Text('Service Category', style: AppTextStyles.labelLarge),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.paddingSM),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
                              ),
                              items: categories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat.toUpperCase(), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)));
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedCategory = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingMD),

                      // Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                                boxShadow: [
                                  BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              padding: const EdgeInsets.all(AppDimensions.paddingMD),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Date', style: AppTextStyles.labelLarge),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimensions.paddingSM),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 60)),
                                      );
                                      if (picked != null) {
                                        setState(() => _selectedDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                      ),
                                      child: Text(DateFormat.MMMEd().format(_selectedDate), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingMD),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                                boxShadow: [
                                  BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              padding: const EdgeInsets.all(AppDimensions.paddingMD),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: AppColors.accent, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Time', style: AppTextStyles.labelLarge),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimensions.paddingSM),
                                  DropdownButtonFormField<String>(
                                    value: _selectedTimeSlot,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSM),
                                    ),
                                    items: _timeSlots.map((slot) {
                                      // Shorten slot text for narrow screens
                                      final shortSlot = slot.replaceAll(' AM', 'am').replaceAll(' PM', 'pm').replaceAll(':00', '');
                                      return DropdownMenuItem(value: slot, child: Text(shortSlot, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedTimeSlot = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),

                      AppTextField(
                        controller: _notesController,
                        label: 'Describe the work',
                        hint: 'Provide details about the issue...',
                        maxLines: 4,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please describe the work';
                          if (val.trim().length < 10) return 'Description must be at least 10 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),

                      AppTextField(
                        controller: _priceController,
                        label: 'Estimated Price (₹)',
                        hint: '0 for to be negotiated',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter 0 if unsure';
                          if (double.tryParse(val) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      Text(
                        'Leave as 0 to negotiate price with the provider after booking.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),

                      // Emergency Toggle
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingMD),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emergency_rounded, color: AppColors.error, size: 28),
                            const SizedBox(width: AppDimensions.paddingMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency / Instant Booking',
                                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Need an electrician within 30 minutes? Add a ₹199 priority fee.',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isEmergency,
                              activeColor: AppColors.error,
                              onChanged: (val) {
                                setState(() {
                                  _isEmergency = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),

                      AppButton(
                        label: 'Send Booking Request',
                        isLoading: _isLoading,
                        onPressed: () => _submitBooking(client, provider),
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      ),
    );
  }
}
