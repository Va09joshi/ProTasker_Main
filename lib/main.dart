import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/theme.dart';
import 'core/providers/app_provider_observer.dart';
import 'core/router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/profile/providers/profile_providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  runApp(
    ProviderScope(
      observers: [AppProviderObserver()],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initializeNotifications();
    PermissionService.requestLocationPermission();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        NotificationService.subscribeToUser(user.uid);
      } else {
        NotificationService.clearSubscriptions();
      }
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    ref.read(isDarkModeProvider.notifier).toggle(isDark);
  }

  Future<void> _initializeNotifications() async {
    await PermissionService.requestNotificationPermission();
    await NotificationService.initializePushDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    ref.watch(isDarkModeProvider);

    return MaterialApp.router(
      title: 'ProTasker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light, // Forced light theme as requested
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
