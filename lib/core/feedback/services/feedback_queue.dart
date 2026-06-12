import 'dart:async';
import 'package:flutter/material.dart';
import '../models/feedback_message.dart';

class FeedbackQueue {
  final List<FeedbackMessage> _queue = [];
  bool _isShowing = false;
  Timer? _debounceTimer;

  static const Duration debounceDuration = Duration(milliseconds: 300);

  void addMessage(FeedbackMessage message, Function(FeedbackMessage) showCallback) {
    // Debounce similar messages
    if (_queue.any((m) => m.message == message.message && m.type == message.type)) {
      return; // Skip duplicate
    }

    _queue.add(message);
    _processQueue(showCallback);
  }

  void _processQueue(Function(FeedbackMessage) showCallback) {
    if (_isShowing || _queue.isEmpty) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      if (_queue.isNotEmpty) {
        _isShowing = true;
        final nextMessage = _queue.removeAt(0);
        showCallback(nextMessage);
      }
    });
  }

  void onMessageDismissed(Function(FeedbackMessage) showCallback) {
    _isShowing = false;
    _processQueue(showCallback);
  }

  void clear() {
    _queue.clear();
    _isShowing = false;
    _debounceTimer?.cancel();
  }
}
