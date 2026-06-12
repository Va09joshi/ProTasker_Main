import 'feedback_type.dart';

class FeedbackMessage {
  final String title;
  final String message;
  final FeedbackType type;
  final String? code;
  final Function()? onRetry;

  const FeedbackMessage({
    this.title = '',
    required this.message,
    required this.type,
    this.code,
    this.onRetry,
  });

  factory FeedbackMessage.success(String message, {String title = ''}) {
    return FeedbackMessage(message: message, title: title, type: FeedbackType.success);
  }

  factory FeedbackMessage.error(String message, {String title = '', String? code, Function()? onRetry}) {
    return FeedbackMessage(message: message, title: title, type: FeedbackType.error, code: code, onRetry: onRetry);
  }

  factory FeedbackMessage.warning(String message, {String title = ''}) {
    return FeedbackMessage(message: message, title: title, type: FeedbackType.warning);
  }

  factory FeedbackMessage.info(String message, {String title = ''}) {
    return FeedbackMessage(message: message, title: title, type: FeedbackType.info);
  }

  factory FeedbackMessage.loading(String message) {
    return FeedbackMessage(message: message, type: FeedbackType.loading);
  }
}
