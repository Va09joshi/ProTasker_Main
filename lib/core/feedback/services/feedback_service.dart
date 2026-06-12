import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feedback_message.dart';
import '../mappers/error_mapper.dart';
import '../feedback_globals.dart';
import 'feedback_queue.dart';
import 'loading_manager.dart';
import '../widgets/feedback_widgets.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

class FeedbackService {
  final FeedbackQueue _queue = FeedbackQueue();

  void showSuccess(String message, {String title = ''}) {
    _show(FeedbackMessage.success(message, title: title));
  }

  void showError(String message, {String title = '', Function()? onRetry}) {
    _show(FeedbackMessage.error(message, title: title, onRetry: onRetry));
  }

  void handleError(dynamic error, {Function()? onRetry}) {
    final message = ErrorMapper.mapError(error, onRetry: onRetry);
    _show(message);
  }

  void showWarning(String message, {String title = ''}) {
    _show(FeedbackMessage.warning(message, title: title));
  }

  void showInfo(String message, {String title = ''}) {
    _show(FeedbackMessage.info(message, title: title));
  }

  void showLoading([String message = 'Loading...']) {
    LoadingManager.show(message);
  }

  void hideLoading() {
    LoadingManager.hide();
  }

  void _show(FeedbackMessage message) {
    _queue.addMessage(message, (msg) {
      if (scaffoldMessengerKey.currentState != null) {
        final snackBar = CustomSnackbar(
          message: msg,
          onDismissed: () => _queue.onMessageDismissed((m) => _show(m)),
        );
        
        scaffoldMessengerKey.currentState!
          .showSnackBar(snackBar)
          .closed
          .then((_) => _queue.onMessageDismissed((m) => _show(m)));
      }
    });
  }
}
