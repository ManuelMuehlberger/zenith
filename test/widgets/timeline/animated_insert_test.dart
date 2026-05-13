import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/timeline/animated_insert.dart';

void main() {
  testWidgets('AnimatedInsert wraps content in fade and size transitions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedInsert(
          animation: AlwaysStoppedAnimation<double>(1),
          child: Text('row'),
        ),
      ),
    );

    final animatedInsert = find.byType(AnimatedInsert);
    expect(
      find.descendant(
        of: animatedInsert,
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: animatedInsert,
        matching: find.byType(SizeTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: animatedInsert,
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('AnimatedInsert adds slide transition when requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedInsert(
          animation: AlwaysStoppedAnimation<double>(1),
          slideInFromBottom: true,
          child: Text('row'),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AnimatedInsert),
        matching: find.byType(SlideTransition),
      ),
      findsOneWidget,
    );
  });
}
