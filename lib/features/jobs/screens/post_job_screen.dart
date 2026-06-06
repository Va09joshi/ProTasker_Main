import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/job_provider.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Home Repair';
  final List<File> _images = [];
  final _imagePicker = ImagePicker();

  final List<String> _categories = [
    'Home Repair',
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Moving',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= 3) {
      SnackbarHelper.error(context, 'You can only upload up to 3 images.');
      return;
    }
    
    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          if (_images.length < 3) {
            _images.add(File(file.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(jobProvider.notifier).postJob(
            _titleController.text.trim(),
            _descController.text.trim(),
            _selectedCategory,
            images: _images,
          );

      if (success && mounted) {
        SnackbarHelper.success(context, 'Problem posted successfully!');
        Navigator.pop(context); // Go back after posting
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isLoading = state.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(jobProvider, (previous, next) {
      if (next.hasError) {
        SnackbarHelper.error(context, next.error.toString());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Problem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Describe what you need help with. Your current location will be automatically attached so nearby providers can find you.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLG),

              AppTextField(
                controller: _titleController,
                label: 'Problem Title',
                hint: 'e.g., Leaking kitchen sink',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.paddingLG),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: isLoading ? null : (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: AppDimensions.paddingLG),

              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Provide details about the issue...',
                maxLines: 5,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.paddingLG),

              const Text('Photos (Optional, max 3)', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.paddingSM),
              if (_images.isEmpty)
                GestureDetector(
                  onTap: isLoading ? null : _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXL),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      border: Border.all(color: AppColors.primary.withAlpha(76), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingMD),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: AppDimensions.paddingMD),
                        Text(
                          'Tap to upload photos',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Show professionals what needs fixing',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...List.generate(_images.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppDimensions.paddingMD),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                                child: Image.file(
                                  _images[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (!isLoading)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(153),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      if (_images.length < 3 && !isLoading)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: AppColors.primary, size: 32),
                                  SizedBox(height: 4),
                                  Text('Add More', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingXL),

              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.locationDot, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Expanded(
                    child: Text(
                      'Your location will be securely shared with nearby providers.',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              AppButton(
                label: 'Post Problem',
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
