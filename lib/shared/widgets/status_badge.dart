import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../models/models.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const StatusBadge({super.key, required this.status});

  Color _color() {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.statusPending;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
        return AppColors.statusAccepted;
      case BookingStatus.inProgress:
        return AppColors.statusActive;
      case BookingStatus.completed:
        return AppColors.statusCompleted;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  String _label() {
    switch (status) {
      case BookingStatus.onTheWay:
        return 'On the Way';
      case BookingStatus.inProgress:
        return 'In Progress';
      default:
        return status.name[0].toUpperCase() + status.name.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text(
        _label(),
        style: AppTextStyles.caption.copyWith(color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
