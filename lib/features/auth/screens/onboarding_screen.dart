import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      'image': 'assets/images/onboarding/planning.gif',
      'title': 'Streamline Your Workflow',
      'subtitle': 'Delegate your everyday tasks to verified professionals. Focus your time and energy on what matters most to you, while our experts handle the heavy lifting with precision and care.',
    },
    {
      'image': 'assets/images/onboarding/efficiency.gif',
      'title': 'Connect with Experts',
      'subtitle': 'Browse through a curated network of top-rated professionals. Compare their skills, read genuine customer reviews, and choose the perfect match for your specific project needs in just a few taps.',
    },
    {
      'image': 'assets/images/onboarding/clipboard-gear.gif',
      'title': 'Track Progress Seamlessly',
      'subtitle': 'Experience complete peace of mind with real-time updates and secure milestone tracking. Our intuitive dashboard keeps you informed every step of the way until the job is done perfectly.',
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
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        Text(
                          page['title'] as String,
                          style: GoogleFonts.lexendDeca(
                            textStyle: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.paddingLG),
                        Text(
                          page['subtitle'] as String,
                          style: GoogleFonts.lexendDeca(
                            textStyle: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _finishOnboarding,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.lexendDeca(
                              textStyle: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF17C37B), // Minty Green to match the image
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x4017C37B),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                )
                              ]
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 28,
                            ),
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
