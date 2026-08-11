import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Bridge between Flutter and Android native code.
/// All launcher-specific Android operations go through this service.
class NativeBridge extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.minimal.launcher/native');

  /// Returns true if this app is currently the default home launcher
  Future<bool> isDefaultLauncher() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDefaultLauncher');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system screen where the user can choose the default launcher
  Future<void> openDefaultLauncherSettings() async {
    try {
      await _channel.invokeMethod('openDefaultLauncherSettings');
    } on PlatformException {
      // Silently ignore – user can still go to settings manually
    }
  }
}
