import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_message.dart';
import '../models/feedback_type.dart';

class ErrorMapper {
  static FeedbackMessage mapError(dynamic error, {Function()? onRetry}) {
    if (error is FirebaseAuthException) {
      return _mapFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      return _mapFirebaseError(error);
    } else if (error is SocketException) {
      return FeedbackMessage.error(
        'No internet connection.\nPlease check your network.',
        title: 'Connection Error',
        code: 'socket_exception',
        onRetry: onRetry,
      );
    } else if (error is FormatException) {
      return FeedbackMessage.error(
        'Data format is invalid. Please contact support if the issue persists.',
        title: 'Format Error',
        code: 'format_exception',
      );
    } else if (error is Exception) {
      return FeedbackMessage.error(
        'Something unexpected happened.\nPlease try again later.',
        title: 'Error',
        code: 'generic_exception',
        onRetry: onRetry,
      );
    }

    return FeedbackMessage.error(
      'An unknown error occurred.\nPlease try again.',
      title: 'Unknown Error',
      code: 'unknown',
      onRetry: onRetry,
    );
  }

  static FeedbackMessage _mapFirebaseAuthError(FirebaseAuthException error) {
    String message;
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        message = 'Unable to sign in.\nPlease check your information.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'email-already-in-use':
        message = 'This email is already registered. Try signing in instead.';
        break;
      case 'weak-password':
        message = 'Your password is too weak. Please use a stronger password.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not permitted. Please try again later.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'requires-recent-login':
        message = 'Please sign in again to complete this action.';
        break;
      default:
        message = 'Authentication failed. Please try again.';
    }
    return FeedbackMessage.error(message, title: 'Authentication Error', code: error.code);
  }

  static FeedbackMessage _mapFirebaseError(FirebaseException error) {
    String message;
    switch (error.code) {
      case 'permission-denied':
        message = 'You do not have permission to perform this action.';
        break;
      case 'unavailable':
        message = 'Service temporarily unavailable.\nPlease try again.';
        break;
      case 'not-found':
        message = 'The requested resource was not found.';
        break;
      default:
        message = 'A server error occurred. Please try again later.';
    }
    return FeedbackMessage.error(message, title: 'Server Error', code: error.code);
  }
}
