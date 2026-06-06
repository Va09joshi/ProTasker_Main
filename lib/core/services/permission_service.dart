import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.status;
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    
    final result = await Permission.photos.request();
    return result.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    
    final result = await Permission.location.request();
    return result.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    final camera = await requestCameraPermission();
    final photos = await requestPhotosPermission();
    final location = await requestLocationPermission();
    final notification = await requestNotificationPermission();
    
    return {
      'camera': camera,
      'photos': photos,
      'location': location,
      'notification': notification,
    };
  }

  static Future<bool> openAppSettings() {
    return permission_handler.openAppSettings();
  }
}
