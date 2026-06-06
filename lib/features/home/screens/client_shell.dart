import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../providers/home_providers.dart';
import '../../chat/providers/chat_providers.dart';

class ClientShell extends ConsumerStatefulWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  int _previousIndex = 0;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/client/bookings')) return 1;
    if (location.startsWith('/client/chat')) return 2;
    if (location.startsWith('/client/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/client/home');
        break;
      case 1:
        context.go('/client/bookings');
        break;
      case 2:
        context.go('/client/chat');
        break;
      case 3:
        context.go('/client/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final bool isForward = currentIndex >= _previousIndex;
    _previousIndex = currentIndex;
    
    final unreadChatsCount = ref.watch(unreadChatsCountProvider);
    final activeBookingsAsync = ref.watch(clientActiveBookingsProvider);

    return RoleGuard.client(
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
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    currentIndex: currentIndex,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month_rounded,
                    label: 'Bookings',
                    index: 1,
                    currentIndex: currentIndex,
                    badgeCount: activeBookingsAsync.value ?? 0,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    index: 2,
                    currentIndex: currentIndex,
                    badgeCount: unreadChatsCount,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
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
