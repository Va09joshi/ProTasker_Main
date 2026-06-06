import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/user_session_provider.dart';

class RoleGuard extends ConsumerWidget {
  final UserRole allowedRole;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRole,
    required this.child,
    this.fallback,
  });

  factory RoleGuard.client({Key? key, required Widget child, Widget? fallback}) {
    return RoleGuard(
      key: key,
      allowedRole: UserRole.client,
      child: child,
      fallback: fallback,
    );
  }

  factory RoleGuard.provider({Key? key, required Widget child, Widget? fallback}) {
    return RoleGuard(
      key: key,
      allowedRole: UserRole.provider,
      child: child,
      fallback: fallback,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModelAsync = ref.watch(currentUserProvider);

    return userModelAsync.when(
      data: (userModel) {
        if (userModel?.role == allowedRole) {
          return child;
        }
        return fallback ?? Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => fallback ?? Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}
