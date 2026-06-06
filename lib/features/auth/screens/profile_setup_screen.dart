import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/services/location_service.dart';
import '../../location/screens/map_picker_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  // Step 1 Controllers
  File? _avatarFile;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  double _lat = 0.0;
  double _lng = 0.0;

  // Step 2 Controllers
  final Set<ServiceCategory> _selectedCategories = {};
  String _experienceYears = '1';
  final _bioController = TextEditingController();
  File? _idProofFile;
  final List<String> _serviceAreas = [];
  final _serviceAreaController = TextEditingController();

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userModel = ref.read(currentUserProvider).value;
      if (userModel != null) {
        _nameController.text = userModel.name;
        _phoneController.text = userModel.phone;
        _streetController.text = userModel.address.street;
        _cityController.text = userModel.address.city;
        _stateController.text = userModel.address.state;
        _pincodeController.text = userModel.address.pincode;
        _lat = userModel.address.lat;
        _lng = userModel.address.lng;
      }
    });
  }

  Future<void> _chooseOnMap() async {
    final result = await context.pushNamed(
      RouteNames.mapPicker,
      queryParameters: {
        if (_lat != 0.0) 'lat': _lat.toString(),
        if (_lng != 0.0) 'lng': _lng.toString(),
      },
    );

    if (result != null && result is MapPickerResult) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        final pm = result.placemark;
        _streetController.text = '${pm.street ?? ''} ${pm.subLocality ?? ''}'.trim();
        _cityController.text = pm.locality ?? pm.subAdministrativeArea ?? '';
        _stateController.text = pm.administrativeArea ?? '';
        _pincodeController.text = pm.postalCode ?? '';
      });
    }
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (isAvatar) {
          _avatarFile = File(pickedFile.path);
        } else {
          _idProofFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      setState(() => _uploadProgress = 0.5);
      final url = await CloudinaryService.uploadFile(file);
      setState(() => _uploadProgress = 1.0);
      return url;
    } catch (e) {
      if (mounted) {
        SnackbarHelper.error(context, 'Upload failed: $e');
      }
      return null;
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      _submitForm();
    }
  }

  void _submitForm() async {
    final userModel = ref.read(currentUserProvider).value;
    if (userModel == null) return;
    
    if (userModel.role == UserRole.provider) {
       if (_selectedCategories.isEmpty) {
         SnackbarHelper.warning(context, 'Please select at least one category');
         return;
       }
       if (_step2FormKey.currentState?.validate() != true) return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _uploadFile(_avatarFile!, 'users/${userModel.uid}/avatar.jpg');
      }

      String? idProofUrl;
      if (userModel.role == UserRole.provider && _idProofFile != null) {
        idProofUrl = await _uploadFile(_idProofFile!, 'users/${userModel.uid}/id_proof.jpg');
      }

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'lat': _lat,
          'lng': _lng,
        },
        'profileComplete': true,
      };

      if (avatarUrl != null) updateData['profilePhoto'] = avatarUrl;

      if (userModel.role == UserRole.client) {
        updateData['interestedServices'] = _selectedCategories.map((c) => c.name).toList();
      } else {
        updateData['offeredServices'] = _selectedCategories.map((c) => c.name).toList();
        updateData['experienceYears'] = _experienceYears;
        updateData['bio'] = _bioController.text.trim();
        if (idProofUrl != null) updateData['idProof'] = idProofUrl;
        updateData['serviceAreas'] = _serviceAreas;
      }

      await ref.read(authNotifierProvider.notifier).updateProfile(userModel.uid, updateData);
      ref.invalidate(currentUserProvider);
      
    } catch (e) {
      if (mounted) {
        SnackbarHelper.error(context, 'Profile setup failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModelAsync = ref.watch(currentUserProvider);
    final userModel = userModelAsync.value;

    if (userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading && _uploadProgress > 0)
              LinearProgressIndicator(value: _uploadProgress, backgroundColor: AppColors.border, color: AppColors.accent),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: AppColors.background,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.accent,
                  ),
                ),
                child: Stepper(
                  physics: const AlwaysScrollableScrollPhysics(),
                  currentStep: _currentStep,
                  onStepContinue: _nextStep,
                  onStepCancel: () {
                    if (_currentStep > 0) setState(() => _currentStep--);
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.paddingLG),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: _currentStep == 1 ? 'Complete Setup' : 'Next',
                              isLoading: _isLoading,
                              onPressed: details.onStepContinue,
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: AppDimensions.paddingMD),
                            Expanded(
                              child: AppButton(
                                label: 'Back',
                                variant: ButtonVariant.ghost,
                                onPressed: _isLoading ? null : details.onStepCancel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Basic Info', style: AppTextStyles.labelLarge),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      content: Form(
                        key: _step1FormKey,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage(true),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppColors.surfaceAlt,
                                    backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                                    child: _avatarFile == null 
                                        ? const Icon(Icons.person_outline, size: 40, color: AppColors.textTertiary) 
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingXL),
                            AppTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: AppDimensions.paddingMD),
                            AppTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: AppDimensions.paddingXL),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Address', style: AppTextStyles.headingMedium),
                                TextButton.icon(
                                  onPressed: _chooseOnMap,
                                  icon: const Icon(Icons.map, size: 18),
                                  label: const Text('Choose on Map'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.paddingMD),
                            AppTextField(
                              controller: _streetController,
                              label: 'Street Address',
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: AppDimensions.paddingMD),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _cityController,
                                    label: 'City',
                                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.paddingMD),
                                Expanded(
                                  child: AppTextField(
                                    controller: _stateController,
                                    label: 'State',
                                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.paddingMD),
                            AppTextField(
                              controller: _pincodeController,
                              label: 'Pincode',
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Step(
                      title: const Text('Service Details', style: AppTextStyles.labelLarge),
                      isActive: _currentStep >= 1,
                      content: userModel.role == UserRole.client ? _buildClientStep2() : _buildProviderStep2(),
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

  Widget _buildClientStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What services are you interested in?', style: AppTextStyles.headingMedium),
        const SizedBox(height: AppDimensions.paddingMD),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: ServiceCategory.values.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategories.remove(category);
                  } else {
                    _selectedCategories.add(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProviderStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service categories offered', style: AppTextStyles.headingMedium),
          const SizedBox(height: AppDimensions.paddingSM),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: ServiceCategory.values.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return CategoryChip(
                category: category,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category);
                    } else {
                      _selectedCategories.add(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          DropdownButtonFormField<String>(
            value: _experienceYears,
            decoration: InputDecoration(
              labelText: 'Years of Experience',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
              filled: true,
              fillColor: AppColors.surface,
            ),
            items: List.generate(20, (index) => (index + 1).toString()).map((e) {
              return DropdownMenuItem(value: e, child: Text('$e year${e == '1' ? '' : 's'}${e == '20' ? '+' : ''}'));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _experienceYears = val);
            },
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          AppTextField(
            controller: _bioController,
            label: 'Professional Bio',
            maxLines: 4,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          const Text('ID Proof Upload', style: AppTextStyles.headingMedium),
          const SizedBox(height: AppDimensions.paddingSM),
          InkWell(
            onTap: () => _pickImage(false),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                color: AppColors.surfaceAlt,
              ),
              child: _idProofFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      child: Image.file(_idProofFile!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingSM),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.upload_file, color: AppColors.accent),
                        ),
                        const SizedBox(height: AppDimensions.paddingMD),
                        Text('Tap to upload ID proof', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          const Text('Service Areas (Cities)', style: AppTextStyles.headingMedium),
          const SizedBox(height: AppDimensions.paddingSM),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _serviceAreaController,
                  label: 'Add city',
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              AppButton(
                label: 'Add',
                fullWidth: false,
                onPressed: () {
                  if (_serviceAreaController.text.isNotEmpty) {
                    setState(() {
                      _serviceAreas.add(_serviceAreaController.text.trim());
                      _serviceAreaController.clear();
                    });
                  }
                },
              ),
            ],
          ),
          if (_serviceAreas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.paddingMD),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _serviceAreas.map((city) {
                  return Chip(
                    label: Text(city),
                    onDeleted: () {
                      setState(() => _serviceAreas.remove(city));
                    },
                    backgroundColor: AppColors.surfaceAlt,
                    deleteIconColor: AppColors.textSecondary,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
