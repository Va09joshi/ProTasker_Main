import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/star_rating.dart';
import '../providers/booking_detail_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const ReviewScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _rating = 0;
  late TextEditingController _reviewCtrl;
  final List<File> _photos = [];
  int _selectedTip = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reviewCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 2) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() => _photos.add(File(file.path)));
    }
  }

  Future<void> _submitReview(BookingModel booking) async {
    if (_rating == 0) {
      SnackbarHelper.warning(context, 'Please select a star rating.');
      return;
    }
    if (_reviewCtrl.text.length < 10) {
      SnackbarHelper.warning(context, 'Review must be at least 10 characters.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final db = FirebaseFirestore.instance;
      final reviewRef = db.collection('reviews').doc();
      final bookingRef = db.collection('bookings').doc(booking.id);
      final providerRef = db.collection('users').doc(booking.providerId);

      // (Skipping actual photo upload to storage here since ReviewModel doesn't persist the URLs currently)
      String comment = _reviewCtrl.text.trim();
      if (_photos.isNotEmpty) {
        comment += '\n\n[Attached ${_photos.length} photos]';
      }

      final review = ReviewModel(
        id: reviewRef.id,
        bookingId: booking.id,
        serviceId: booking.serviceId,
        reviewerId: booking.clientId,
        reviewerName: booking.clientName,
        reviewerPhoto: booking.clientPhoto,
        providerId: booking.providerId,
        rating: _rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await db.runTransaction((tx) async {
        final providerDoc = await tx.get(providerRef);
        final currentRating = (providerDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
        final currentTotalReviews = providerDoc.data()?['totalReviews'] as int? ?? 0; 

        final newTotalReviews = currentTotalReviews + 1;
        final newRating = ((currentRating * currentTotalReviews) + _rating) / newTotalReviews;

        tx.set(reviewRef, review.toMap());
        tx.update(bookingRef, {'clientReviewed': true});
        tx.update(providerRef, {
          'rating': newRating,
          'totalReviews': newTotalReviews,
        });
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLG)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                const Text('Review Submitted!', style: AppTextStyles.headingLarge),
                const SizedBox(height: AppDimensions.paddingSM),
                const Text('Thank you for sharing your experience.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context); 
          context.go('/client/home'); 
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        SnackbarHelper.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingDetailStreamProvider(widget.bookingId));

    return RoleGuard.client(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Leave a Review'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: bookingAsync.when(
            data: (booking) {
              if (booking == null) return const Center(child: Text('Booking not found'));
  
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProviderInfo(booking),
                    const SizedBox(height: AppDimensions.paddingXL),
                    
                    const Text('How was your experience?', style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
                    const SizedBox(height: AppDimensions.paddingMD),
                    Center(
                      child: StarRating(
                        rating: _rating,
                        size: 48,
                        readOnly: false,
                        onRatingChanged: (val) => setState(() => _rating = val),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    
                    AppTextField(
                      controller: _reviewCtrl,
                      label: 'Write a review',
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppDimensions.paddingMD),
                    
                    Row(
                      children: [
                        if (_photos.length < 2)
                          GestureDetector(
                            onTap: _pickPhoto,
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
                        ..._photos.asMap().entries.map((e) => Stack(
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
                                onTap: () => setState(() => _photos.removeAt(e.key)),
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
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    
                    const Text('Tip your provider (Optional)', style: AppTextStyles.headingLarge),
                    const SizedBox(height: AppDimensions.paddingMD),
                    _buildTipRow(),
                    const SizedBox(height: AppDimensions.paddingXL),
                    
                    AppButton(
                      label: 'Submit Review',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? () {} : () => _submitReview(booking),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
            loading: () => const LoadingShimmer(type: ShimmerType.profile),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(bookingDetailStreamProvider(widget.bookingId))),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderInfo(BookingModel booking) {
    return Column(
      children: [
        AppAvatar(name: booking.providerName, imageUrl: booking.providerPhoto, size: 80),
        const SizedBox(height: AppDimensions.paddingMD),
        Text(booking.providerName, style: AppTextStyles.displayMedium),
        const SizedBox(height: 4),
        Text(booking.serviceTitle, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTipRow() {
    final tips = [20, 50, 100];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ...tips.map((amount) {
          final isSelected = _selectedTip == amount;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTip = amount),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: AppDimensions.cardBorderWidth,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                alignment: Alignment.center,
                child: Text('₹$amount', style: AppTextStyles.labelLarge.copyWith(color: isSelected ? AppColors.accent : AppColors.textPrimary)),
              ),
            ),
          );
        }),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTip = -1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedTip == -1 ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
                border: Border.all(
                  color: _selectedTip == -1 ? AppColors.accent : AppColors.border,
                  width: AppDimensions.cardBorderWidth,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              alignment: Alignment.center,
              child: Text('Custom', style: AppTextStyles.labelLarge.copyWith(color: _selectedTip == -1 ? AppColors.accent : AppColors.textPrimary)),
            ),
          ),
        ),
      ],
    );
  }
}
