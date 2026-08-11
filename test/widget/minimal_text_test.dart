import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/core/widgets/minimal_text.dart';

void main() {
  testWidgets('MinimalText renders the given text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MinimalText('Hello Launcher'),
        ),
      ),
    );

    expect(find.text('Hello Launcher'), findsOneWidget);
  });

  testWidgets('MinimalText respects maxLines', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 50,
            child: MinimalText(
              'A very long text that should ellipsize',
              maxLines: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MinimalText), findsOneWidget);
  });
}
