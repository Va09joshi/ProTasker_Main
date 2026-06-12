import 'package:flutter/material.dart';
import '../../router/app_router.dart';
import '../widgets/feedback_widgets.dart';

class LoadingManager {
  static bool _isLoading = false;
  static BuildContext? _loadingContext;

  static void show([String message = 'Loading...']) {
    if (_isLoading) return;
    _isLoading = true;

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext ctx) {
        _loadingContext = ctx;
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: LoadingOverlay(message: message),
        );
      },
    );
  }

  static void hide() {
    if (!_isLoading) return;
    
    if (_loadingContext != null && Navigator.of(_loadingContext!).canPop()) {
      Navigator.of(_loadingContext!).pop();
    }
    
    _isLoading = false;
    _loadingContext = null;
  }
}
