class AppException implements Exception {
  final String code;
  final String message;

  AppException({required this.code, required this.message});

  factory AppException.auth(String message) {
    return AppException(code: 'auth-error', message: message);
  }

  factory AppException.network(String message) {
    return AppException(code: 'network-error', message: message);
  }

  factory AppException.firestore(String message) {
    return AppException(code: 'firestore-error', message: message);
  }

  @override
  String toString() {
    return message;
  }
}
