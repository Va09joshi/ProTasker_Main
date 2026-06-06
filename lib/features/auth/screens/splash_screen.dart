import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/constants/app_images.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));
    
    _controller.forward();
    _checkNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
      if (seenOnboarding) {
        context.go(RoutePaths.login);
      } else {
        context.go(RoutePaths.onboarding);
      }
    } else {
      final userModelAsync = ref.read(currentUserProvider);
      final userModel = userModelAsync.value;

      if (userModel == null || !userModel.profileComplete) {
        context.go(RoutePaths.profileSetup);
      } else if (userModel.role == UserRole.client) {
        context.go(RoutePaths.clientHome);
      } else {
        context.go(RoutePaths.providerDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      AppImages.logo,
                      width: 340,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
