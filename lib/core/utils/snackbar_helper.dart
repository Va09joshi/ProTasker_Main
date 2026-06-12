import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feedback/services/feedback_service.dart';

class SnackbarHelper {
  static void success(BuildContext context, String message) {
    if (!context.mounted) return;
    ProviderScope.containerOf(context).read(feedbackServiceProvider).showSuccess(message);
  }

  static void error(BuildContext context, String message) {
    if (!context.mounted) return;
    ProviderScope.containerOf(context).read(feedbackServiceProvider).showError(message);
  }

  static void info(BuildContext context, String message) {
    if (!context.mounted) return;
    ProviderScope.containerOf(context).read(feedbackServiceProvider).showInfo(message);
  }

  static void warning(BuildContext context, String message) {
    if (!context.mounted) return;
    ProviderScope.containerOf(context).read(feedbackServiceProvider).showWarning(message);
  }
}
