import 'package:shared_preferences/shared_preferences.dart';

/// Call at the start of tests that use StorageService / SharedPreferences.
Future<void> setupTestStorage({Map<String, Object>? values}) async {
  SharedPreferences.setMockInitialValues(values ?? {});
}
