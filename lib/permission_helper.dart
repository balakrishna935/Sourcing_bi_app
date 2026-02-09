import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<void> requestAllPermissions() async {
    await [
      Permission.phone,

    ].request();
  }
}
