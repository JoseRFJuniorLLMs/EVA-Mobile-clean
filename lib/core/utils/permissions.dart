import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> requestCallPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
    ].request();

    return statuses[Permission.microphone]!.isGranted;
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    final basicPermissions = await [
      Permission.microphone,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();

    basicPermissions.forEach((permission, status) {
      results[permission.toString()] = status.isGranted;
    });

    return results;
  }
}
