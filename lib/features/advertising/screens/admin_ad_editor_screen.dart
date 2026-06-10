import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../models/custom_ad_model.dart';
import '../repositories/custom_ad_repository.dart';

class AdminAdEditorScreen extends ConsumerStatefulWidget {
  final CustomAdModel? existingAd;

  const AdminAdEditorScreen({super.key, this.existingAd});

  @override
  ConsumerState<AdminAdEditorScreen> createState() => _AdminAdEditorScreenState();
}

class _AdminAdEditorScreenState extends ConsumerState<AdminAdEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _targetUrlCtrl;
  late TextEditingController _priorityCtrl;
  
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final ad = widget.existingAd;
    _titleCtrl = TextEditingController(text: ad?.title ?? '');
    _descCtrl = TextEditingController(text: ad?.description ?? '');
    _targetUrlCtrl = TextEditingController(text: ad?.targetUrl ?? '');
    _priorityCtrl = TextEditingController(text: ad?.priority.toString() ?? '0');
    
    if (ad != null) {
      _isActive = ad.isActive;
      _startDate = ad.startDate;
      _endDate = ad.endDate;
      _existingImageUrl = ad.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetUrlCtrl.dispose();
    _priorityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String adId) async {
    if (_selectedImage == null) return _existingImageUrl;
    
    try {
      final ext = _selectedImage!.path.split('.').last;
      final ref = FirebaseStorage.instance.ref().child('ads/$adId.$ext');
      final uploadTask = await ref.putFile(_selectedImage!);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null && _existingImageUrl == null) {
      SnackbarHelper.warning(context, 'Please upload an image for the ad.');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      SnackbarHelper.error(context, 'End date cannot be before start date.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adId = widget.existingAd?.id ?? const Uuid().v4();
      final imageUrl = await _uploadImage(adId);

      if (imageUrl == null) {
        throw Exception('Image upload failed');
      }

      final ad = CustomAdModel(
        id: adId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        targetUrl: _targetUrlCtrl.text.trim(),
        isActive: _isActive,
        priority: int.tryParse(_priorityCtrl.text) ?? 0,
        startDate: _startDate,
        endDate: _endDate,
        impressions: widget.existingAd?.impressions ?? 0,
        clicks: widget.existingAd?.clicks ?? 0,
      );

      final repo = ref.read(customAdRepositoryProvider);
      if (widget.existingAd == null) {
        await repo.createAd(ad);
      } else {
        await repo.updateAd(ad);
      }

      if (mounted) {
        context.pop();
        SnackbarHelper.success(context, 'Ad saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.error(context, 'Failed to save ad: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingAd == null ? 'Create Ad' : 'Edit Ad', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Upload
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                        border: Border.all(color: AppColors.border),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : (_existingImageUrl != null
                                ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                                : null),
                      ),
                      child: (_selectedImage == null && _existingImageUrl == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text('Upload Ad Banner', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),

                  // Status Toggle
                  SwitchListTile(
                    title: const Text('Active Status', style: AppTextStyles.labelLarge),
                    subtitle: Text('Enable or disable this ad campaign', style: AppTextStyles.caption),
                    value: _isActive,
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                  const Divider(),
                  const SizedBox(height: AppDimensions.paddingMD),

                  AppTextField(
                    controller: _titleCtrl,
                    label: 'Ad Title',
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),

                  AppTextField(
                    controller: _descCtrl,
                    label: 'Description (Optional)',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),

                  AppTextField(
                    controller: _targetUrlCtrl,
                    label: 'Target Redirect URL',
                    hint: 'https://example.com',
                    keyboardType: TextInputType.url,
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final uri = Uri.tryParse(val);
                        if (uri == null || !uri.hasScheme) return 'Enter a valid URL starting with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),

                  AppTextField(
                    controller: _priorityCtrl,
                    label: 'Priority (Higher shows first)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Date', style: AppTextStyles.labelLarge),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) setState(() => _startDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(DateFormat.yMd().format(_startDate)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingLG),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Date', style: AppTextStyles.labelLarge),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) setState(() => _endDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(DateFormat.yMd().format(_endDate)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  AppButton(
                    label: widget.existingAd == null ? 'Create Ad' : 'Update Ad',
                    onPressed: _saveAd,
                  ),
                  
                  if (widget.existingAd != null) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Delete Ad',
                      variant: ButtonVariant.secondary,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Ad?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          setState(() => _isLoading = true);
                          await ref.read(customAdRepositoryProvider).deleteAd(widget.existingAd!.id);
                          if (mounted) {
                            context.pop();
                            SnackbarHelper.info(context, 'Ad deleted');
                          }
                        }
                      },
                    ),
                  ]
                ],
              ),
            ),
          ),
    );
  }
}
