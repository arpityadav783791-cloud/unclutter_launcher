import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';

void main() {
  group('AppInfo', () {
    test('fromMap', () {
      final app = AppInfo.fromMap({
        'name': 'Chrome',
        'packageName': 'com.android.chrome',
        'isSystemApp': true,
      });
      expect(app.name, 'Chrome');
      expect(app.packageName, 'com.android.chrome');
      expect(app.isSystemApp, true);
    });

    test('equality by packageName', () {
      const a = AppInfo(name: 'A', packageName: 'com.test');
      const b = AppInfo(name: 'B', packageName: 'com.test');
      const c = AppInfo(name: 'A', packageName: 'com.other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toMap round-trip', () {
      const original = AppInfo(
        name: 'Maps',
        packageName: 'com.google.maps',
        isSystemApp: false,
      );
      final restored = AppInfo.fromMap(original.toMap());
      expect(restored.name, original.name);
      expect(restored.packageName, original.packageName);
      expect(restored.isSystemApp, false);
    });
  });
}
