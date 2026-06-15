import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/models/service_model.dart';
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
  final List<File> _images = [];
  final _imagePicker = ImagePicker();
  ServiceCategory _selectedCategory = ServiceCategory.cleaning;
  
  final List<ServiceCategory> _categories = ServiceCategory.values;

  // Stepper state
  int _currentStep = 0;
  final int _totalSteps = 3;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pageController.dispose();
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

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      // Validate Title before moving to Description
      if (_titleController.text.trim().isEmpty) {
        SnackbarHelper.error(context, 'Please enter a work title');
        return;
      }
    } else if (_currentStep == 1) {
      // Validate Description
      if (_descController.text.trim().isEmpty) {
        SnackbarHelper.error(context, 'Please enter a description');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(jobProvider.notifier).postJob(
            _titleController.text.trim(),
            _descController.text.trim(),
            _selectedCategory.name,
            images: _images,
          );

      if (success && mounted) {
        SnackbarHelper.success(context, 'Work posted successfully!');
        Navigator.pop(context); // Go back after posting
      }
    }
  }

  Widget _buildStepperHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingLG, horizontal: AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_totalSteps * 2 - 1, (index) {
          if (index % 2 != 0) {
            // Divider line
            final stepIndex = index ~/ 2;
            final isActiveLine = _currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: isActiveLine ? AppColors.accent : (isDark ? AppColors.darkBorder : AppColors.border),
              ),
            );
          } else {
            // Step Circle
            final stepIndex = index ~/ 2;
            final isActive = _currentStep >= stepIndex;
            final isCompleted = _currentStep > stepIndex;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: isActive ? AppColors.accent : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : (isDark ? AppColors.textHint : AppColors.textSecondary),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildStep1(bool isDark, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Step 1: Basics', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppDimensions.paddingSM),
          Text(
            'Start by giving your task a clear title and selecting the right category so professionals can find it easily.',
            style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          AppTextField(
            controller: _titleController,
            label: 'Work Title',
            hint: 'e.g., Leaking kitchen sink',
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            enabled: !isLoading,
          ),
          const SizedBox(height: AppDimensions.paddingLG),

          DropdownButtonFormField<ServiceCategory>(
            value: _selectedCategory,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
            elevation: 4,
            dropdownColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: isDark ? AppColors.darkBackground : AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingMD),
            ),
            items: _categories.map((c) => DropdownMenuItem(
              value: c, 
              child: Text(c.displayName),
            )).toList(),
            onChanged: isLoading ? null : (val) => setState(() => _selectedCategory = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Step 2: Details', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppDimensions.paddingSM),
          Text(
            'Describe what needs to be done. The more details you provide, the better quotes you will receive.',
            style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          AppTextField(
            controller: _descController,
            label: 'Description',
            hint: 'Provide details about the issue...',
            maxLines: 6,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            enabled: !isLoading,
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.locationDot, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location Attached', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Your current location will be securely shared with nearby providers.',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Step 3: Photos (Optional)', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppDimensions.paddingSM),
          Text(
            'A picture is worth a thousand words. Show professionals exactly what needs fixing.',
            style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          if (_images.isEmpty)
            GestureDetector(
              onTap: isLoading ? null : _pickImages,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, color: AppColors.info, size: 36),
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    Text(
                      'Tap to upload photos',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max 3 images',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
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
                              width: 140,
                              height: 140,
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
                                  padding: const EdgeInsets.all(6),
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
                        width: 140,
                        height: 140,
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
        ],
      ),
    );
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
        title: const Text('Post Work'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepperHeader(isDark),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                  _buildStep1(isDark, isLoading),
                  _buildStep2(isDark, isLoading),
                  _buildStep3(isDark, isLoading),
                ],
              ),
            ),
            
            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: AppButton(
                          label: 'Back',
                          variant: ButtonVariant.secondary,
                          onPressed: isLoading ? null : _prevStep,
                        ),
                      ),
                    if (_currentStep > 0)
                      const SizedBox(width: AppDimensions.paddingMD),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: _currentStep == _totalSteps - 1 ? 'Post Work' : 'Next',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _nextStep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
