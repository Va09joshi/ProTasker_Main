import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center', style: AppTextStyles.headingLarge),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        children: [
          _buildSearchBox(isDark),
          const SizedBox(height: AppDimensions.paddingXL),
          Text(
            'Frequently Asked Questions',
            style: AppTextStyles.headingMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          _buildFaqItem(
            'How do I book a service?',
            'To book a service, navigate to the Home screen, search for your desired category, and select a service provider. Choose a date and time, and confirm your booking.',
            isDark,
          ),
          _buildFaqItem(
            'How do I make a payment?',
            'Payments are securely processed through our application. You can add a credit card or use supported mobile wallets in the checkout screen once a job is complete.',
            isDark,
          ),
          _buildFaqItem(
            'Can I cancel a booking?',
            'Yes, you can cancel a booking from the "Bookings" tab. Please note that cancellations made within 24 hours of the scheduled time may incur a cancellation fee.',
            isDark,
          ),
          _buildFaqItem(
            'How do I contact my provider?',
            'Once your booking is confirmed, you can use the in-app Chat feature to communicate directly with your service provider regarding any details.',
            isDark,
          ),
          _buildFaqItem(
            'What if Im not satisfied?',
            'We strive for 100% satisfaction. If you have an issue with a completed job, please reach out to our support team within 48 hours for dispute resolution.',
            isDark,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Text(
            'Still need help?',
            style: AppTextStyles.headingMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          _buildContactButton(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat with Support',
            subtitle: 'Available 24/7',
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat support coming soon!')),
              );
            },
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          _buildContactButton(
            icon: Icons.email_outlined,
            title: 'Email Us',
            subtitle: 'vaibhavjoshi0709@gmail.com',
            isDark: isDark,
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'vaibhavjoshi0709@gmail.com',
                queryParameters: {
                  'subject': 'Support Request: ProTasker',
                },
              );
              try {
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch email app')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error opening email client')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search for help topics...',
          icon: Icon(Icons.search, color: AppColors.textTertiary),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          iconColor: AppColors.accent,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.paddingLG, 0, AppDimensions.paddingLG, AppDimensions.paddingLG),
              child: Text(
                answer,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
