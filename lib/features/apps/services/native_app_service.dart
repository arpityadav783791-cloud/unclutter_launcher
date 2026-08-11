import 'package:flutter/services.dart';

import '../models/app_model.dart';

class NativeAppService {
  static const MethodChannel _channel = MethodChannel(
    'minimalist_launcher/native_apps',
  );

  Future<List<AppModel>> getInstalledApps() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getInstalledApps',
    );

    if (result == null) {
      return [];
    }

    return result
        .map((app) => AppModel.fromMap(Map<dynamic, dynamic>.from(app as Map)))
        .toList();
  }
}
