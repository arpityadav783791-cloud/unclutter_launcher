import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/favorites/models/favorite_app.dart';

void main() {
  group('FavoriteApp', () {
    test('serialization round-trip', () {
      final original = FavoriteApp(packageName: 'com.test', order: 2);
      final restored = FavoriteApp.fromMap(original.toMap());
      expect(restored.packageName, 'com.test');
      expect(restored.order, 2);
    });

    test('copyWith', () {
      final base = FavoriteApp(packageName: 'com.test', order: 0);
      final updated = base.copyWith(order: 3);
      expect(updated.order, 3);
      expect(updated.packageName, 'com.test');
    });
  });
}
