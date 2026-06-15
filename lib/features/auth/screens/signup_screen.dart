import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/constants/app_images.dart';
import '../../../shared/models/models.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/feedback/services/feedback_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String roleName;

  const SignupScreen({super.key, required this.roleName});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;
  int _loadingType = 0; // 0 = none, 1 = normal, 2 = google

  void _signup() async {
    setState(() => _loadingType = 1);
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmController.text) {
        SnackbarHelper.error(context, 'Passwords do not match.');
        return;
      }
      
      if (!_termsAccepted) {
        SnackbarHelper.error(context, 'Please accept the Terms & Conditions');
        return;
      }
      
      final String roleStr = widget.roleName.toLowerCase();
      UserRole role = roleStr == 'provider' ? UserRole.provider : UserRole.client;

      await ref.read(authNotifierProvider.notifier).signup(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: role,
          );
    }
  }

  void _signupWithGoogle() async {
    setState(() => _loadingType = 2);
    // Since Google sign up will now redirect to role selection if they don't have a role,
    // we can just call loginWithGoogle. The AppRouter will handle the rest!
    await ref.read(authNotifierProvider.notifier).loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ref.read(feedbackServiceProvider).handleError(error);
        },
      );
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimensions.paddingLG),
                  Image.asset(
                    AppImages.logo,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  const SizedBox(height: AppDimensions.paddingSM),
                  Text(
                    'Sign up as a ${widget.roleName}',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  
                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  
                  AppTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    validator: (value) => value == null || !value.contains('@') ? 'Enter valid email' : null,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter phone number';
                      if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Phone number must be exactly 10 digits';
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    obscure: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a password';
                      }
                      if (value.length < 8) {
                        return 'Must be at least 8 characters long';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Must contain at least one uppercase letter';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return 'Must contain at least one lowercase letter';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Must contain at least one number';
                      }
                      if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                        return 'Must contain at least one special character (!@#\$&*~)';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  
                  AppTextField(
                    controller: _confirmController,
                    label: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    obscure: true,
                    validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),
                  
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          activeColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.textTertiary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: isLoading ? null : (val) => setState(() => _termsAccepted = val ?? false),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingSM),
                      Expanded(
                        child: Text(
                          'I agree to the Terms & Conditions',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),
                  
                  AppButton(
                    label: 'Create Account',
                    isLoading: isLoading && _loadingType == 1,
                    onPressed: isLoading ? null : _signup,
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),
                  
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
                        child: Text(
                          'OR',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),

                  // Google button
                  AppButton(
                    label: 'Sign up with Google',
                    iconWidget: Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) => const FaIcon(FontAwesomeIcons.google, size: 20),
                    ),
                    variant: ButtonVariant.secondary,
                    isLoading: isLoading && _loadingType == 2,
                    onPressed: isLoading ? null : _signupWithGoogle,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: AppTextStyles.bodyMedium),
                      GestureDetector(
                        onTap: isLoading ? null : () => context.go(RoutePaths.login),
                        child: Text(
                          'Login',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
