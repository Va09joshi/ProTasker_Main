import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    debugPrint('Provider added: \${context.provider.name ?? context.provider.runtimeType}');
  }

  @override
  void didUpdateProvider(ProviderObserverContext context, Object? previousValue, Object? newValue) {
    debugPrint('Provider updated: \${context.provider.name ?? context.provider.runtimeType}');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    debugPrint('Provider disposed: \${context.provider.name ?? context.provider.runtimeType}');
  }

  @override
  void providerDidFail(ProviderObserverContext context, Object error, StackTrace stackTrace) {
    debugPrint('Provider failed: \${context.provider.name ?? context.provider.runtimeType}');
    debugPrint('Error: $error');
    debugPrint('StackTrace: $stackTrace');
  }
}
