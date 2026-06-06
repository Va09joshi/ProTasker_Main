import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: AppTextStyles.headingLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: June 2026',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            _buildSection(
              title: '1. Introduction',
              content: 'Welcome to ProTasker. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our application and tell you about your privacy rights and how the law protects you.',
              isDark: isDark,
            ),
            _buildSection(
              title: '2. The Data We Collect',
              content: 'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:\n\n• Identity Data: includes first name, last name, username or similar identifier.\n• Contact Data: includes billing address, delivery address, email address and telephone numbers.\n• Location Data: includes precise and approximate location to connect you with nearby services.',
              isDark: isDark,
            ),
            _buildSection(
              title: '3. How We Use Your Data',
              content: 'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n• Where we need to perform the contract we are about to enter into or have entered into with you.\n• Where it is necessary for our legitimate interests and your interests and fundamental rights do not override those interests.\n• Where we need to comply with a legal obligation.',
              isDark: isDark,
            ),
            _buildSection(
              title: '4. Data Security',
              content: 'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.',
              isDark: isDark,
            ),
            _buildSection(
              title: '5. Your Legal Rights',
              content: 'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to request access, correction, erasure, restriction, transfer, to object to processing, to portability of data and to withdraw consent.',
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
