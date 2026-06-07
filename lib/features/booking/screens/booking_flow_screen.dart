import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../services/providers/service_detail_provider.dart';
import '../providers/booking_flow_providers.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const BookingFlowScreen({super.key, required this.serviceId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  late PageController _pageController;

  late TextEditingController _streetCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _notesCtrl;

  bool _addressPrefilled = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _streetCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _pincodeCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _prefillAddress(UserModel clientUser) {
    if (_addressPrefilled) return;
    _addressPrefilled = true;
    final addr = clientUser.address;
    _streetCtrl.text = addr.street;
    _cityCtrl.text = addr.city;
    _stateCtrl.text = addr.state;
    _pincodeCtrl.text = addr.pincode;
  }

  void _nextStep(int currentStep) {
    if (currentStep < 3) {
      ref.read(bookingFlowProvider.notifier).setStep(currentStep + 1);
      _pageController.animateToPage(currentStep + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep(int currentStep) {
    if (currentStep > 0) {
      ref.read(bookingFlowProvider.notifier).setStep(currentStep - 1);
      _pageController.animateToPage(currentStep - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitBooking(ServiceModel service, UserModel clientUser, UserModel providerUser) async {
    final state = ref.read(bookingFlowProvider);
    if (state.selectedDate == null || state.timeSlot == null) return;

    ref.read(bookingFlowProvider.notifier).setLoading(true);

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final bookingRef = db.collection('bookings').doc();

      List<String> notesPhotos = [];
      for (int i = 0; i < state.tempPhotos.length; i++) {
        final url = await CloudinaryService.uploadFile(state.tempPhotos[i]);
        if (url != null) notesPhotos.add(url);
      }

      final address = Address(
        street: _streetCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        lat: clientUser.address.lat,
        lng: clientUser.address.lng,
      );

      final grossPrice = service.basePrice;
      final platformFee = grossPrice * 0.10;
      final netPrice = grossPrice - platformFee;

      final fullNotes = [
        if (state.specialInstructions.isNotEmpty) 'Tags: ${state.specialInstructions.join(', ')}',
        if (_notesCtrl.text.isNotEmpty) _notesCtrl.text,
        if (notesPhotos.isNotEmpty) 'Attached ${notesPhotos.length} photos.'
      ].join('\n\n');

      final booking = BookingModel(
        id: bookingRef.id,
        clientId: clientUser.uid,
        clientName: clientUser.name,
        clientPhone: clientUser.phone,
        clientPhoto: clientUser.profilePhoto,
        providerId: service.providerId,
        providerName: service.providerName,
        providerPhone: providerUser.phone, 
        providerPhoto: service.providerPhoto,
        serviceId: service.id,
        serviceTitle: service.title,
        serviceCategory: service.category,
        scheduledAt: state.selectedDate!,
        timeSlot: state.timeSlot!,
        status: BookingStatus.pending,
        address: address,
        grossPrice: grossPrice,
        platformFee: platformFee,
        netPrice: netPrice,
        notes: fullNotes,
        proofImages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        otp: (Random().nextInt(9000) + 1000).toString(),
      );

      batch.set(bookingRef, booking.toMap());

      final notifRef = db.collection('notifications').doc();
      final notification = NotificationModel(
        id: notifRef.id,
        userId: service.providerId,
        title: 'New Booking Request',
        body: '${clientUser.name} requested ${service.title}.',
        type: NotificationType.bookingRequest,
        payload: {'bookingId': bookingRef.id},
        isRead: false,
        createdAt: DateTime.now(),
      );
      batch.set(notifRef, notification.toMap());

      await batch.commit();

      ref.read(bookingFlowProvider.notifier).setLoading(false);
      
      if (mounted) {
        context.pop(); // dismiss flow
        SnackbarHelper.success(context, 'Booking request sent successfully!');
      }

    } catch (e) {
      ref.read(bookingFlowProvider.notifier).setLoading(false);
      if (mounted) SnackbarHelper.error(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));
    final clientAsync = ref.watch(currentUserProvider);

    return RoleGuard.client(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Book Service'),
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: serviceAsync.when(
            data: (service) {
              if (service == null) return const Center(child: Text('Service not found'));
              
              return clientAsync.when(
                data: (client) {
                  if (client == null) return const Center(child: Text('User error'));
                  _prefillAddress(client);
  
                  final providerAsync = ref.watch(bookingProviderUserModelProvider(service.providerId));
                  
                  return providerAsync.when(
                    data: (provider) {
                      if (provider == null) return const Center(child: Text('Provider not found'));
  
                      return _buildFlow(service, client, provider);
                    },
                    loading: () => const LoadingShimmer(type: ShimmerType.profile),
                    error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(bookingProviderUserModelProvider(service.providerId))),
                  );
                },
                loading: () => const LoadingShimmer(type: ShimmerType.profile),
                error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(currentUserProvider)),
              );
            },
            loading: () => const LoadingShimmer(type: ShimmerType.profile),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(serviceDetailProvider(widget.serviceId))),
          ),
        ),
      ),
    );
  }

  Widget _buildFlow(ServiceModel service, UserModel client, UserModel provider) {
    final state = ref.watch(bookingFlowProvider);

    return Column(
      children: [
        LinearProgressIndicator(
          value: (state.currentStep + 1) / 4,
          backgroundColor: AppColors.surfaceAlt,
          color: AppColors.accent,
          minHeight: 4,
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildScheduleStep(service, provider),
              _buildAddressStep(),
              _buildNotesStep(),
              _buildSummaryStep(service, client, provider),
            ],
          ),
        ),
        _buildBottomBar(service, client, provider, state),
      ],
    );
  }

  Widget _buildBottomBar(ServiceModel service, UserModel client, UserModel provider, BookingFlowState state) {
    final bool canProceed = _canProceed(state);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: AppDimensions.cardBorderWidth)),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              child: AppButton(
                label: 'Back',
                variant: ButtonVariant.ghost,
                onPressed: state.isLoading ? () {} : () => _prevStep(state.currentStep),
              ),
            )
          else
            const Spacer(),
            
          const SizedBox(width: AppDimensions.paddingMD),
          
          Expanded(
            flex: 2,
            child: AppButton(
              label: state.currentStep == 3 ? 'Confirm & Book' : 'Continue',
              isLoading: state.isLoading,
              onPressed: canProceed && !state.isLoading ? () {
                if (state.currentStep == 3) {
                  _submitBooking(service, client, provider);
                } else {
                  _nextStep(state.currentStep);
                }
              } : () {}, // Note: empty callback effectively disables it if we use our internal disabled styling if not canProceed. However, AppButton does not have a disabled property, so we just pass empty function or null. Let's pass a function that does nothing. Actually, let's let AppButton take a null onPressed if !canProceed. Wait, AppButton requires onPressed. We will just ignore it.
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed(BookingFlowState state) {
    if (state.currentStep == 0) {
      return state.selectedDate != null && state.timeSlot != null;
    }
    if (state.currentStep == 1) {
      return _streetCtrl.text.isNotEmpty && _cityCtrl.text.isNotEmpty && _stateCtrl.text.isNotEmpty && _pincodeCtrl.text.isNotEmpty;
    }
    return true; // Notes are optional, summary is final
  }

  // --- Step 1 ---
  Widget _buildScheduleStep(ServiceModel service, UserModel providerUser) {
    final state = ref.watch(bookingFlowProvider);
    final notifier = ref.read(bookingFlowProvider.notifier);
    
    bool isDayDisabled(DateTime day) {
      if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return true;
      if (providerUser.availabilitySchedule != null) {
        final dayName = DateFormat('EEEE').format(day);
        final dayConfig = providerUser.availabilitySchedule![dayName];
        if (dayConfig != null && dayConfig['enabled'] == false) return true;
      }
      return false;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
        vertical: AppDimensions.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Date', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingMD),
          Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusMD), border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth)),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: state.selectedDate ?? DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(state.selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isDayDisabled(selectedDay)) {
                  notifier.setDate(selectedDay);
                }
              },
              enabledDayPredicate: (day) => !isDayDisabled(day),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                selectedTextStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.background),
                defaultTextStyle: AppTextStyles.bodyMedium,
                disabledTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTextStyles.labelLarge,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          
          if (state.selectedDate != null) ...[
            const Text('Select Time Slot', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppDimensions.paddingMD),
            _buildTimeSlots(service.providerId, state.selectedDate!),
          ]
        ],
      ),
    );
  }

  Widget _buildTimeSlots(String providerId, DateTime date) {
    final bookedSlotsAsync = ref.watch(providerBookedSlotsProvider((providerId: providerId, date: date)));
    final state = ref.watch(bookingFlowProvider);
    final notifier = ref.read(bookingFlowProvider.notifier);

    final slots = ['Morning 8-12', 'Afternoon 12-5', 'Evening 5-9'];

    return bookedSlotsAsync.when(
      data: (bookedSlots) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((slot) {
            final isBooked = bookedSlots.contains(slot);
            final isSelected = state.timeSlot == slot;
            
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              selectedColor: AppColors.accent.withValues(alpha: 0.1),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: AppDimensions.cardBorderWidth,
              ),
              onSelected: isBooked ? null : (val) {
                if (val) notifier.setTimeSlot(slot);
              },
              labelStyle: AppTextStyles.labelLarge.copyWith(
                color: isBooked ? AppColors.textHint : (isSelected ? AppColors.accent : AppColors.textPrimary),
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            );
          }).toList(),
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.card),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerBookedSlotsProvider((providerId: providerId, date: date)))),
    );
  }

  // --- Step 2 ---
  Widget _buildAddressStep() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
        vertical: AppDimensions.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Address', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingMD),
          AppButton(
            label: 'Use saved address',
            icon: Icons.history_rounded,
            variant: ButtonVariant.secondary,
            onPressed: () {
              SnackbarHelper.info(context, 'Address is already pre-filled from your profile.');
            },
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          AppTextField(controller: _streetCtrl, label: 'Street Address', onChanged: (_) => setState((){})),
          const SizedBox(height: AppDimensions.paddingMD),
          AppTextField(controller: _cityCtrl, label: 'City', onChanged: (_) => setState((){})),
          const SizedBox(height: AppDimensions.paddingMD),
          AppTextField(controller: _stateCtrl, label: 'State', onChanged: (_) => setState((){})),
          const SizedBox(height: AppDimensions.paddingMD),
          AppTextField(controller: _pincodeCtrl, label: 'Pincode', onChanged: (_) => setState((){})),
        ],
      ),
    );
  }

  // --- Step 3 ---
  Widget _buildNotesStep() {
    final state = ref.watch(bookingFlowProvider);
    final notifier = ref.read(bookingFlowProvider.notifier);

    final tags = ['Bring tools', 'Call before arriving', 'Wear mask', 'No pets'];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
        vertical: AppDimensions.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Special Instructions', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingMD),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = state.specialInstructions.contains(tag);
              return FilterChip(
                label: Text(tag, style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                )),
                selected: isSelected,
                selectedColor: AppColors.accent.withValues(alpha: 0.1),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: AppDimensions.cardBorderWidth,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
                onSelected: (_) => notifier.toggleInstruction(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          AppTextField(
            controller: _notesCtrl,
            label: 'Additional Notes (Optional)',
            maxLines: 4,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attach Photos', style: AppTextStyles.labelLarge),
              Text('${state.tempPhotos.length}/3', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            children: [
              if (state.tempPhotos.length < 3)
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (file != null) notifier.addPhoto(File(file.path));
                  },
                  child: Container(
                    width: 80, height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth), 
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: AppColors.textSecondary),
                  ),
                ),
              ...state.tempPhotos.asMap().entries.map((e) => Stack(
                children: [
                  Container(
                    width: 80, height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      image: DecorationImage(image: FileImage(e.value), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 12,
                    child: GestureDetector(
                      onTap: () => notifier.removePhoto(e.key),
                      child: CircleAvatar(
                        radius: 12, 
                        backgroundColor: AppColors.background.withValues(alpha: 0.8), 
                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textPrimary)
                      ),
                    ),
                  )
                ],
              )),
            ],
          )
        ],
      ),
    );
  }

  // --- Step 4 ---
  Widget _buildSummaryStep(ServiceModel service, UserModel client, UserModel provider) {
    final state = ref.watch(bookingFlowProvider);
    final gross = service.basePrice;
    final fee = gross * 0.10;
    final total = gross + fee;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
        vertical: AppDimensions.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Summary', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingLG),
          
          _buildSummarySectionWidget('Service', [
            Text(service.title, style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text('Provider: ${provider.name}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ]),
          
          _buildSummarySectionWidget('Schedule', [
            Text(DateFormat.yMMMMd().format(state.selectedDate!), style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(state.timeSlot ?? '', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ]),
          
          _buildSummarySectionWidget('Location', [
            Text('${_streetCtrl.text}, ${_cityCtrl.text}', style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text('${_stateCtrl.text} - ${_pincodeCtrl.text}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ]),
          
          _buildSummarySectionWidget('Payment', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Base Price', style: AppTextStyles.bodyMedium),
                Text('₹${gross.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Platform Fee (10%)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                Text('₹${fee.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingMD),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: AppTextStyles.labelLarge),
                Text('₹${total.toStringAsFixed(2)}', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary)),
              ],
            ),
          ]),
          
          const SizedBox(height: AppDimensions.paddingMD),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            decoration: BoxDecoration(
              color: AppColors.surface, 
              border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth), 
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD)
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payments_rounded, color: AppColors.success),
                ),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cash on Completion', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text('Online payment coming soon', style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySectionWidget(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            decoration: BoxDecoration(
              color: AppColors.surface, 
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
