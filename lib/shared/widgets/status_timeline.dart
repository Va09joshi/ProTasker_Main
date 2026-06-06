import 'package:flutter/material.dart';
import '../../shared/models/models.dart';
import '../../core/theme/theme.dart';

class StatusTimeline extends StatelessWidget {
  final BookingStatus currentStatus;
  const StatusTimeline({super.key, required this.currentStatus});

  int get _currentIndex {
    switch (currentStatus) {
      case BookingStatus.pending: return 0;
      case BookingStatus.accepted: return 1;
      case BookingStatus.onTheWay: return 2;
      case BookingStatus.inProgress: return 3;
      case BookingStatus.completed: return 4;
      case BookingStatus.cancelled:
      case BookingStatus.rejected: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == -1) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Booking ${currentStatus.name}', style: AppTextStyles.headingMedium.copyWith(color: AppColors.error)),
          ],
        ),
      );
    }

    final steps = ['Requested', 'Accepted', 'On The Way', 'In Progress', 'Completed'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < _currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.accent : AppColors.border,
            ),
          );
        } else {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < _currentIndex;
          final isCurrent = stepIndex == _currentIndex;

          return Column(
            children: [
              if (isCurrent)
                const _PulsingCircle(color: AppColors.accent)
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.accent : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: isCompleted ? AppColors.accent : AppColors.border, width: 2),
                  ),
                  child: isCompleted ? const Icon(Icons.check, size: 14, color: AppColors.background) : null,
                ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: AppTextStyles.caption.copyWith(
                  color: isCurrent ? AppColors.accent : (isCompleted ? AppColors.textPrimary : AppColors.textTertiary),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}

class _PulsingCircle extends StatefulWidget {
  final Color color;
  const _PulsingCircle({required this.color});

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween(begin: 1.0, end: 1.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Container(
            width: 16 * _animation.value,
            height: 16 * _animation.value,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      },
    );
  }
}
