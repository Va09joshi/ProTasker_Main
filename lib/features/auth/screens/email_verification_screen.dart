import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isChecking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    
    // Automatically send initial email link on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resendVerification(showSnackbar: false);
      _startVerificationPolling();
    });
  }

  void _startVerificationPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            timer.cancel();
            // Force a token refresh to trigger authStateChanges and wake up the router
            await user.getIdToken(true);
            if (mounted) {
              SnackbarHelper.success(context, 'Email verified successfully!');
              context.go(RoutePaths.profileSetup);
            }
          }
        }
      } catch (e) {
        // Ignore reload errors during polling (e.g. network issues)
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Force refresh user token to get updated emailVerified status
        await user.reload();
        if (user.emailVerified) {
          // Force a token refresh to trigger authStateChanges and wake up the router
          await user.getIdToken(true);
          if (mounted) {
            SnackbarHelper.success(context, 'Email verified successfully!');
            context.go(RoutePaths.profileSetup);
          }
        } else {
          if (mounted) {
            SnackbarHelper.warning(context, 'Email is not verified yet. Please check your inbox.');
          }
        }
      }
    } catch (e) {
      if (mounted) SnackbarHelper.error(context, 'Failed to check verification status.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerification({bool showSnackbar = true}) async {
    try {
      await ref.read(authNotifierProvider.notifier).sendEmailVerification();
      if (mounted && showSnackbar) {
        SnackbarHelper.success(context, 'Verification link sent to your email!');
      }
    } catch (e) {
      if (mounted && showSnackbar) {
        SnackbarHelper.error(context, e.toString());
      }
    }
  }

  void _logout() {
    ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading || _isChecking;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingMD),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance for centering
                  Text(
                    'Verify Email',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600 ? 48.0 : AppDimensions.paddingLG,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Animated GIF Container
                          Center(
                            child: Image.asset(
                              'assets/email-file.gif',
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),
                          
                          // Title
                          Text(
                            'Verify Your Email Address',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.paddingMD),
                          
                          // Subtitle & Email
                          Text(
                            'We have sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.paddingSM),
                          Text(
                            user?.email ?? 'your email address',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: AppDimensions.padding40),
                          
                          // Action Buttons
                          AppButton(
                            label: "I've Verified",
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _checkVerificationStatus,
                          ),
                          const SizedBox(height: AppDimensions.paddingLG),
                          
                          // Resend button
                          TextButton(
                            onPressed: isLoading ? null : () => _resendVerification(showSnackbar: true),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh_rounded, 
                                  size: 18, 
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary
                                ),
                                const SizedBox(width: AppDimensions.paddingSM),
                                Text(
                                  'Resend Verification Email',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
