import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSigningUp = ref.watch(isSigningUpProvider);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.paddingLG),
              Text(
                'How do you want to use ProTasker?',
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                'Select your primary goal so we can tailor your experience.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.padding40),
              
              _buildRoleCard(
                title: 'I need a service',
                subtitle: 'Find and book professionals for your tasks',
                imageAsset: 'assets/images/boy.gif',
                role: UserRole.client,
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              _buildRoleCard(
                title: 'I provide services',
                subtitle: 'Offer your skills and earn money',
                imageAsset: 'assets/images/multitasking.gif',
                role: UserRole.provider,
              ),
              
              const Spacer(),
              AppButton(
                label: 'Continue',
                isLoading: isSigningUp,
                onPressed: _selectedRole == null || isSigningUp
                    ? null
                    : () async {
                        final authState = ref.read(authStateProvider).value;
                        if (authState != null) {
                          // User is already authenticated (e.g. Google Sign-In) but lacks a role
                          await ref.read(authNotifierProvider.notifier).completeGoogleSignup(_selectedRole!);
                        } else {
                          // Normal flow: go to signup screen
                          final roleString = _selectedRole == UserRole.provider ? 'provider' : 'client';
                          if (context.mounted) {
                            context.pushNamed(RouteNames.signup, queryParameters: {'role': roleString});
                          }
                        }
                      },
              ),
              const SizedBox(height: AppDimensions.paddingMD),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String imageAsset,
    required UserRole role,
  }) {
    final isSelected = _selectedRole == role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF374151) : AppColors.border),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] 
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 6.0 : 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

