import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/images/onboarding/onboarding1.png',
      'title': 'Post Your Tasks',
      'subtitle': 'Easily describe your work and get it in front of qualified professionals.',
    },
    {
      'image': 'assets/images/onboarding/onboarding2.png',
      'title': 'Find the Right Pro',
      'subtitle': 'Compare skills, ratings, and quotes to choose the best expert for the job.',
    },
    {
      'image': 'assets/images/onboarding/onboarding3.png',
      'title': 'Get Things Done',
      'subtitle': 'Relax while our trusted professionals handle your tasks efficiently and securely.',
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go(RoutePaths.roleSelect);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        Image.asset(
                          page['image'] as String,
                          height: 280,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        Text(
                          page['title'] as String,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.paddingLG),
                        Text(
                          page['subtitle'] as String,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = _currentIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  if (_currentIndex == _pages.length - 1)
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Get Started',
                        onPressed: _finishOnboarding,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Skip',
                            variant: ButtonVariant.text,
                            onPressed: _finishOnboarding,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingMD),
                        Expanded(
                          child: AppButton(
                            label: 'Next',
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
