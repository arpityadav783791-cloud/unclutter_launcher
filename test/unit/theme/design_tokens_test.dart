import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/core/theme/app_spacing.dart';
import 'package:minimal_launcher/core/theme/app_radius.dart';
import 'package:minimal_launcher/core/theme/app_typography.dart';
import 'package:minimal_launcher/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  group('Design Tokens Tests', () {
    test('AppSpacing tokens follow 4dp grid scale', () {
      expect(AppSpacing.xxs, equals(2.0));
      expect(AppSpacing.xs, equals(4.0));
      expect(AppSpacing.sm, equals(8.0));
      expect(AppSpacing.md, equals(12.0));
      expect(AppSpacing.lg, equals(16.0));
      expect(AppSpacing.xl, equals(20.0));
      expect(AppSpacing.xxl, equals(24.0));
      expect(AppSpacing.xxxl, equals(32.0));
      expect(AppSpacing.huge, equals(48.0));
    });

    test('AppRadius tokens are correctly defined', () {
      expect(AppRadius.none, equals(0.0));
      expect(AppRadius.xs, equals(4.0));
      expect(AppRadius.sm, equals(8.0));
      expect(AppRadius.md, equals(12.0));
      expect(AppRadius.lg, equals(16.0));
      expect(AppRadius.xl, equals(24.0));
      expect(AppRadius.borderSm.topLeft.x, equals(8.0));
      expect(AppRadius.topLg.topRight.x, equals(16.0));
    });

    test('AppTypography provides standard styles', () {
      expect(AppTypography.clock.fontSize, equals(52));
      expect(AppTypography.screenTitle.fontSize, equals(22));
      expect(AppTypography.appTitle.fontSize, equals(19));
      expect(AppTypography.body.fontSize, equals(16));
      expect(AppTypography.button.fontSize, equals(15));
      expect(AppTypography.caption.fontSize, equals(11));
    });

    testWidgets('AppTheme responsive helpers return bounded values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final hPadding = AppTheme.horizontalPadding(context);
              final vPadding = AppTheme.verticalPadding(context);
              final clockSize = AppTheme.responsiveClockFontSize(context);
              final appTitleSize = AppTheme.responsiveAppTitleFontSize(context);

              expect(hPadding, inInclusiveRange(16.0, 32.0));
              expect(vPadding, inInclusiveRange(16.0, 32.0));
              expect(clockSize, inInclusiveRange(40.0, 60.0));
              expect(appTitleSize, inInclusiveRange(18.0, 22.0));

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
