import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/apps/models/app_config.dart';

void main() {
  group('AppConfig', () {
    test('displayName uses custom name when set', () {
      final config = AppConfig(
        packageName: 'com.instagram.android',
        customName: 'Social',
      );
      expect(config.displayName('Instagram'), 'Social');
    });

    test('displayName falls back to original', () {
      final config = AppConfig(packageName: 'com.instagram.android');
      expect(config.displayName('Instagram'), 'Instagram');
    });

    test('displayName ignores blank custom name', () {
      final config = AppConfig(
        packageName: 'com.test',
        customName: '   ',
      );
      expect(config.displayName('Original'), 'Original');
    });

    test('hidden flag', () {
      final config = AppConfig(
        packageName: 'com.test',
        isHidden: true,
      );
      expect(config.isHidden, true);
    });

    test('serialization round-trip', () {
      final original = AppConfig(
        packageName: 'com.test',
        customName: 'My App',
        isHidden: true,
      );
      final restored = AppConfig.fromMap(original.toMap());
      expect(restored.packageName, 'com.test');
      expect(restored.customName, 'My App');
      expect(restored.isHidden, true);
    });

    test('copyWith clearCustomName', () {
      final base = AppConfig(
        packageName: 'com.test',
        customName: 'Custom',
      );
      final cleared = base.copyWith(clearCustomName: true);
      expect(cleared.customName, isNull);
    });
  });
}
