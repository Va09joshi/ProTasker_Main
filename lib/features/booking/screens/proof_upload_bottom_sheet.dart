import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';

class ProofUploadBottomSheet extends ConsumerStatefulWidget {
  final BookingModel booking;
  const ProofUploadBottomSheet({super.key, required this.booking});

  @override
  ConsumerState<ProofUploadBottomSheet> createState() => _ProofUploadBottomSheetState();
}

class _ProofUploadBottomSheetState extends ConsumerState<ProofUploadBottomSheet> {
  final List<File> _images = [];
  bool _isUploading = false;
  double _progress = 0.0;

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      SnackbarHelper.warning(context, 'Maximum 3 photos allowed.');
      return;
    }
    
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file != null) {
      setState(() => _images.add(File(file.path)));
    }
  }

  Future<void> _completeJob() async {
    if (_images.isEmpty) {
      SnackbarHelper.warning(context, 'Please upload at least 1 proof photo.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> photoUrls = [];
      
      for (int i = 0; i < _images.length; i++) {
        setState(() => _progress = (i / _images.length) * 0.5);
        final url = await CloudinaryService.uploadFile(_images[i]);
        if (url != null) photoUrls.add(url);
      }

      setState(() => _progress = 0.75);

      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      
      final bookingRef = db.collection('bookings').doc(widget.booking.id);
      batch.update(bookingRef, {
        'status': BookingStatus.completed.name,
        'proofImages': photoUrls,
        'clientReviewed': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final notifRef = db.collection('notifications').doc();
      final notification = NotificationModel(
        id: notifRef.id,
        userId: widget.booking.clientId, 
        title: 'Job Completed',
        body: '${widget.booking.providerName} has completed your ${widget.booking.serviceTitle} job.',
        type: NotificationType.bookingCompleted,
        payload: {'bookingId': widget.booking.id},
        isRead: false,
        createdAt: DateTime.now(),
      );
      batch.set(notifRef, notification.toMap());

      await batch.commit();

      setState(() => _progress = 1.0);
      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.success(context, 'Job marked as complete!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.error(context, 'Error: $e');
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppDimensions.paddingLG,
        right: AppDimensions.paddingLG,
        top: AppDimensions.paddingLG,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle(),
          const SizedBox(height: AppDimensions.paddingMD),
          const Text('Upload Proof of Work', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingSM),
          Text('Please upload 1-3 photos showing the completed work.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.paddingLG),
          
          if (_images.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length < 3 ? _images.length + 1 : 3,
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    return GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          image: DecorationImage(image: FileImage(_images[index]), fit: BoxFit.cover),
                        ),
                      ),
                      if (!_isUploading)
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(index)),
                            child: CircleAvatar(
                              radius: 12, 
                              backgroundColor: AppColors.background.withValues(alpha: 0.8), 
                              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textPrimary)
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            )
          else
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 48, color: AppColors.textHint),
                    const SizedBox(height: AppDimensions.paddingSM),
                    Text('Take Photo', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            
          const SizedBox(height: AppDimensions.paddingLG),
          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _progress, 
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceAlt,
              minHeight: 4,
            ),
            const SizedBox(height: AppDimensions.paddingLG),
          ],
          AppButton(
            label: _isUploading ? 'Uploading...' : 'Confirm Cash & Complete',
            isLoading: _isUploading,
            onPressed: _isUploading ? () {} : _completeJob,
          ),
          const SizedBox(height: AppDimensions.paddingLG),
        ],
      ),
    );
  }
}
