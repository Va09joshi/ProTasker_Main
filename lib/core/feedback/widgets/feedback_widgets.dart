import 'package:flutter/material.dart';
import '../models/feedback_message.dart';
import '../models/feedback_type.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSnackbar extends SnackBar {
  CustomSnackbar({
    super.key,
    required FeedbackMessage message,
    required VoidCallback onDismissed,
  }) : super(
          content: _SnackbarContent(message: message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          elevation: 6,
          duration: const Duration(seconds: 4),
          backgroundColor: _getBackgroundColor(message.type),
          onVisible: () {},
        );

  static Color _getBackgroundColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Colors.green.shade800;
      case FeedbackType.error:
        return Colors.red.shade800;
      case FeedbackType.warning:
        return Colors.orange.shade800;
      case FeedbackType.info:
      default:
        return Colors.blue.shade800;
    }
  }
}

class _SnackbarContent extends StatelessWidget {
  final FeedbackMessage message;

  const _SnackbarContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_getIcon(message.type), color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.title.isNotEmpty)
                Text(
                  message.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              Text(
                message.message,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (message.onRetry != null)
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              message.onRetry!();
            },
            child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  IconData _getIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle_outline;
      case FeedbackType.error:
        return Icons.error_outline;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.info:
      default:
        return Icons.info_outline;
    }
  }
}
