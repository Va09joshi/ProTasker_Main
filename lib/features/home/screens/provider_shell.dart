import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../providers/provider_dashboard_providers.dart';
import '../../chat/providers/chat_providers.dart';

class ProviderShell extends ConsumerStatefulWidget {
  final Widget child;
  const ProviderShell({super.key, required this.child});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
  int _previousIndex = 0;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/provider/jobs')) return 1;
    if (location.startsWith('/provider/earnings')) return 2;
    if (location.startsWith('/provider/chat')) return 3;
    if (location.startsWith('/provider/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/provider/dashboard');
        break;
      case 1:
        context.go('/provider/jobs');
        break;
      case 2:
        context.go('/provider/earnings');
        break;
      case 3:
        context.go('/provider/chat');
        break;
      case 4:
        context.go('/provider/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final bool isForward = currentIndex >= _previousIndex;
    _previousIndex = currentIndex;
    
    final pendingBadgeAsync = ref.watch(providerPendingRequestsBadgeProvider);
    final unreadChatsCount = ref.watch(unreadChatsCountProvider);

    return RoleGuard.provider(
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: AppDimensions.cardBorderWidth)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    label: 'Home',
                    index: 0,
                    currentIndex: currentIndex,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.work_outline_rounded,
                    selectedIcon: Icons.work_rounded,
                    label: 'Jobs',
                    index: 1,
                    currentIndex: currentIndex,
                    badgeCount: pendingBadgeAsync.value ?? 0,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    selectedIcon: Icons.account_balance_wallet_rounded,
                    label: 'Earnings',
                    index: 2,
                    currentIndex: currentIndex,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    index: 3,
                    currentIndex: currentIndex,
                    badgeCount: unreadChatsCount,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                    currentIndex: currentIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required int currentIndex,
    int badgeCount = 0,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.textTertiary;
    
    Widget iconWidget = Icon(isSelected ? selectedIcon : icon, color: color);
    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(badgeCount.toString()),
        backgroundColor: AppColors.error,
        child: iconWidget,
      );
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                width: isSelected ? 40 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
