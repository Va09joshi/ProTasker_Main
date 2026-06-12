import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/constants/app_images.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/feedback/services/feedback_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  int _loadingType = 0;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _loadingType = 1; });
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
      } else {
        await prefs.remove('remembered_email');
      }

      await ref.read(authNotifierProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        setState(() { _loadingType = 0; });
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() { _loadingType = 2; });
    await ref.read(authNotifierProvider.notifier).loginWithGoogle();
    if (mounted) {
      setState(() { _loadingType = 0; });
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) {
        final resetEmailController = TextEditingController();
        return AlertDialog(
          title: const Text('Reset Password'),
          content: AppTextField(
            controller: resetEmailController,
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(AppDimensions.paddingLG, 0, AppDimensions.paddingLG, AppDimensions.paddingLG),
          actions: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: ButtonVariant.ghost,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppDimensions.padding12),
                Expanded(
                  child: AppButton(
                    label: 'Send',
                    onPressed: () async {
                      Navigator.pop(context);
                      if (resetEmailController.text.isNotEmpty) {
                        await ref.read(authNotifierProvider.notifier).resetPassword(resetEmailController.text.trim());
                        if (mounted) {
                          SnackbarHelper.success(context, 'Password reset email sent');
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          // Use the new FeedbackService to safely map and show the error!
          ref.read(feedbackServiceProvider).handleError(error);
        },
      );
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 48.0 : AppDimensions.paddingLG,
              vertical: AppDimensions.paddingXL,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top spacing
                      const SizedBox(height: AppDimensions.padding40),

                      // Logo
                      Image.asset(
                        AppImages.logo,
                        width: 280,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),

                      // Subtitle
                      Text(
                        'Sign In to continue',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.padding40),

                      // Email Field
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.solidEnvelope, size: 18),
                          ],
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter email' : null,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),

                      // Password Field
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.lock, size: 18),
                          ],
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        obscure: _obscurePassword,
                        validator: (value) => value == null || value.isEmpty ? 'Enter password' : null,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),

                      // Remember me & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: isLoading ? null : _forgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),

                      // Sign In Button
                      AppButton(
                        label: 'Sign In',
                        isLoading: isLoading && _loadingType == 1,
                        onPressed: isLoading ? null : _login,
                      ),
                      const SizedBox(height: AppDimensions.paddingLG),

                      // Google button
                      AppButton(
                        label: 'Sign in with Google',
                        iconWidget: Image.network(
                          'https://developers.google.com/identity/images/g-logo.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) => const FaIcon(FontAwesomeIcons.google, size: 20),
                        ),
                        variant: ButtonVariant.secondary,
                        isLoading: isLoading && _loadingType == 2,
                        onPressed: isLoading ? null : _loginWithGoogle,
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Dont have any account? ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading ? null : () => context.push(RoutePaths.roleSelect),
                            child: Text(
                              'Register',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
