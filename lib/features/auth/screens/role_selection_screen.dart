import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        backgroundColor: Colors.transparent,
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
                icon: Icons.person_search_rounded,
                role: UserRole.client,
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              _buildRoleCard(
                title: 'I provide services',
                subtitle: 'Offer your skills and earn money',
                icon: Icons.handyman_rounded,
                role: UserRole.provider,
              ),
              
              const Spacer(),
              AppButton(
                label: 'Continue',
                onPressed: _selectedRole == null
                    ? null
                    : () {
                        context.push('${RoutePaths.signup}?role=${_selectedRole!.name}');
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
    required IconData icon,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563),
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

