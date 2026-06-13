import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/user_session_provider.dart';
import '../../shared/models/models.dart';
import 'route_names.dart';
import '../../features/auth/screens/screens.dart';

import '../../features/home/screens/client_shell.dart';
import '../../features/home/screens/client_home_screen.dart';
import '../../features/location/screens/client_map_screen.dart';
import '../../features/booking/screens/client_bookings_screen.dart';
import '../../features/profile/screens/client_profile_screen.dart';
import '../../features/profile/screens/help_center_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/public_provider_profile_screen.dart';

import '../../features/home/screens/provider_shell.dart';
import '../../features/home/screens/provider_dashboard_screen.dart';
import '../../features/booking/screens/provider_jobs_screen.dart';
import '../../features/home/screens/provider_earnings_screen.dart';
import '../../features/profile/screens/provider_profile_screen.dart';
import '../../features/jobs/screens/post_job_screen.dart';
import '../../features/jobs/screens/job_feed_screen.dart';
import '../../features/jobs/screens/client_jobs_screen.dart';
import '../../features/jobs/screens/job_detail_screen.dart';

import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';

import '../../features/home/screens/search_screen.dart';
import '../../features/services/screens/screens.dart';
import '../../features/booking/screens/booking_flow_screen.dart';
import '../../features/booking/screens/booking_detail_screen.dart';
import '../../features/booking/screens/review_screen.dart';
import '../../features/profile/screens/notification_screen.dart';
import '../../features/location/screens/map_picker_screen.dart';
import '../../features/services/screens/category_providers_screen.dart';
import '../../features/booking/screens/direct_booking_screen.dart';
import '../../features/advertising/screens/admin_ads_dashboard.dart';
import '../../features/advertising/screens/admin_ad_editor_screen.dart';
import '../../features/advertising/models/custom_ad_model.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _clientShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'clientShell');
final _providerShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'providerShell');

CustomTransitionPage _buildPageWithFadeTransition<T>(
  BuildContext context, 
  GoRouterState state, 
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: child,
      );
    },
  );
}

CustomTransitionPage _buildPageWithSlideTransition<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final userModelAsync = ref.read(currentUserProvider);

      final unauthRoutes = [
        RoutePaths.splash,
        RoutePaths.onboarding,
        RoutePaths.roleSelect,
        RoutePaths.login,
        RoutePaths.signup,
      ];
      final isUnauthRoute = unauthRoutes.contains(state.matchedLocation);

      if (authState.isLoading || userModelAsync.isLoading) {
        return null; 
      }

      final user = authState.value;
      if (user == null) {
        return isUnauthRoute ? null : RoutePaths.login;
      }

      final userModel = userModelAsync.value;
      if (userModel == null) {
        if (state.matchedLocation == RoutePaths.profileSetup) return null;
        return RoutePaths.profileSetup;
      }

      if (!userModel.profileComplete) {
        if (state.matchedLocation == RoutePaths.profileSetup) return null;
        return RoutePaths.profileSetup;
      }

      if (isUnauthRoute || state.matchedLocation == RoutePaths.profileSetup) {
        if (userModel.role == UserRole.client) {
          return '/client/home';
        } else if (userModel.role == UserRole.provider) {
          return '/provider/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.roleSelect,
        name: RouteNames.roleSelect,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'client';
          return SignupScreen(roleName: role);
        },
      ),
      GoRoute(
        path: RoutePaths.profileSetup,
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      
      // Client Shell
      ShellRoute(
        navigatorKey: _clientShellNavigatorKey,
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/client/home',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ClientHomeScreen()),
          ),
          GoRoute(
            path: '/client/bookings',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ClientBookingsScreen()),
          ),
          GoRoute(
            path: '/client/map',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ClientMapScreen()),
          ),
          GoRoute(
            path: '/client/chat',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ChatListScreen()),
          ),
          GoRoute(
            path: '/client/profile',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ClientProfileScreen()),
          ),
          GoRoute(
            path: '/client/post-job',
            name: RouteNames.postJob,
            pageBuilder: (context, state) => _buildPageWithSlideTransition(context, state, const PostJobScreen()),
          ),
          GoRoute(
            path: '/client/category-providers/:category',
            name: 'categoryProviders',
            pageBuilder: (context, state) {
              final category = state.pathParameters['category']!;
              return _buildPageWithFadeTransition(context, state, CategoryProvidersScreen(category: category));
            },
          ),
        ],
      ),

      // Provider Shell
      ShellRoute(
        navigatorKey: _providerShellNavigatorKey,
        builder: (context, state, child) => ProviderShell(child: child),
        routes: [
          GoRoute(
            path: '/provider/dashboard',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ProviderDashboardScreen()),
          ),
          GoRoute(
            path: '/provider/jobs',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ProviderJobsScreen()),
          ),
          GoRoute(
            path: '/provider/earnings',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ProviderEarningsScreen()),
          ),
          GoRoute(
            path: '/provider/chat',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ChatListScreen()),
          ),
          GoRoute(
            path: '/provider/profile',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(context, state, const ProviderProfileScreen()),
          ),
          GoRoute(
            path: '/provider/job-feed',
            name: RouteNames.jobFeed,
            builder: (context, state) => const JobFeedScreen(),
          ),
        ],
      ),

      // Shared Routes
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/services',
        name: 'serviceList',
        builder: (context, state) {
          final categoryStr = state.uri.queryParameters['category'];
          ServiceCategory? category;
          if (categoryStr != null) {
            try { category = ServiceCategory.values.byName(categoryStr); } catch (_) {}
          }
          return ServiceListScreen(category: category);
        },
      ),
      GoRoute(
        path: '/service/:id',
        name: 'serviceDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ServiceDetailScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: '/booking-flow/:serviceId',
        name: 'bookingFlow',
        builder: (context, state) {
          final id = state.pathParameters['serviceId']!;
          return BookingFlowScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: '/booking/:id',
        name: 'bookingDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookingDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/provider/:id',
        name: 'publicProviderProfile',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicProviderProfileScreen(providerId: id);
        },
      ),
      GoRoute(
        path: '/client/book-provider/:id',
        name: 'bookProvider',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final category = state.uri.queryParameters['category'];
          return DirectBookingScreen(providerId: id, category: category);
        },
      ),
      GoRoute(
        path: '/review/:bookingId',
        name: 'review',
        builder: (context, state) {
          final id = state.pathParameters['bookingId']!;
          return ReviewScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chatScreen',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPageWithSlideTransition(context, state, ChatScreen(chatId: id));
        },
      ),
      GoRoute(
        path: '/my-jobs',
        name: 'myJobs',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(context, state, const ClientJobsScreen()),
      ),
      GoRoute(
        path: '/job/:id',
        name: 'jobDetail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPageWithSlideTransition(context, state, JobDetailScreen(jobId: id));
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: RoutePaths.notificationSettings,
        name: RouteNames.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/help-center',
        name: 'helpCenter',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: RoutePaths.mapPicker,
        name: RouteNames.mapPicker,
        builder: (context, state) {
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
          return MapPickerScreen(initialLat: lat, initialLng: lng);
        },
      ),
      GoRoute(
        path: '/admin/ads',
        name: 'adminAds',
        builder: (context, state) => const AdminAdsDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/ads/edit',
        name: 'adminAdEditor',
        builder: (context, state) {
          final ad = state.extra as CustomAdModel?;
          return AdminAdEditorScreen(existingAd: ad);
        },
      ),
    ],
  );
});
