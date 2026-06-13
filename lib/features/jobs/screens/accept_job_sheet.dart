import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/models/models.dart';
import '../../booking/repositories/booking_repository.dart';
import '../models/job_post.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';

class AcceptJobSheet extends ConsumerStatefulWidget {
  final JobPost job;
  final UserModel provider;
  final UserModel client;

  const AcceptJobSheet({
    super.key,
    required this.job,
    required this.provider,
    required this.client,
  });

  @override
  ConsumerState<AcceptJobSheet> createState() => _AcceptJobSheetState();
}

class _AcceptJobSheetState extends ConsumerState<AcceptJobSheet> {
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:00 AM - 11:00 AM';

  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final double price = double.parse(_priceController.text);
      final bookingId = const Uuid().v4();

      final booking = BookingModel(
        id: bookingId,
        clientId: widget.job.clientId,
        clientName: widget.client.name,
        clientPhone: widget.client.phone,
        clientPhoto: widget.client.profilePhoto,
        providerId: widget.provider.uid,
        providerName: widget.provider.name,
        providerPhone: widget.provider.phone,
        providerPhoto: widget.provider.profilePhoto,
        serviceId: widget.job.id,
        serviceTitle: widget.job.title,
        serviceCategory: ServiceCategory.values.firstWhere(
          (e) => e.name == widget.job.category,
          orElse: () => ServiceCategory.other,
        ),
        scheduledAt: _selectedDate,
        timeSlot: _selectedTimeSlot,
        status: BookingStatus.proposal, // Provider Proposal
        address: Address(
          street: 'Provided by Client',
          city: '',
          state: '',
          pincode: '',
          lat: widget.job.latitude,
          lng: widget.job.longitude,
        ),
        grossPrice: price,
        platformFee: 0.0, // Neglected platform fee
        netPrice: price,
        notes: widget.job.description,
        proofImages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        otp: (Random().nextInt(9000) + 1000).toString(),
      );

      // Create Booking
      await ref.read(bookingRepositoryProvider).createBooking(booking);

      // Notify the client
      await NotificationService.sendNotification(
        targetUid: widget.job.clientId,
        title: 'New Proposal Received',
        body: '${widget.provider.name} has sent a proposal for "${widget.job.title}".',
      );

      // We do not change the job status to in_progress yet, because multiple providers can submit proposals.
      // Once the client accepts a specific booking, the job becomes in_progress.

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal submitted successfully! Waiting for client approval.')),
        );
        // Navigate to provider bookings or keep them on the job feed
        context.go('/provider/jobs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit proposal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppDimensions.paddingXL,
        right: AppDimensions.paddingXL,
        top: AppDimensions.paddingXL,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                Text('Submit Proposal', style: AppTextStyles.headingLarge),
                const SizedBox(height: AppDimensions.paddingMD),
                Text(
                  'Offer your estimated price and availability for this job. The client will review your proposal.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                AppTextField(
                  controller: _priceController,
                  label: 'Estimated Price (₹)',
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter a price';
                    if (double.tryParse(val) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingLG),

                // Date Selection
                Text('Available Date', style: AppTextStyles.labelLarge),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: AppDimensions.paddingLG),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: AppTextStyles.bodyLarge,
                        ),
                        const Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLG),

                // Time Slot Selection
                Text('Time Slot', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.paddingSM),
                DropdownButtonFormField<String>(
                  value: _selectedTimeSlot,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
                  ),
                  items: _timeSlots.map((slot) {
                    return DropdownMenuItem(value: slot, child: Text(slot));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTimeSlot = val);
                    }
                  },
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                AppButton(
                  label: 'Submit Proposal',
                  isLoading: _isLoading,
                  onPressed: _submitProposal,
                ),
                const SizedBox(height: AppDimensions.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
