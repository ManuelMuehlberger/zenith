import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/timeline/achievement_model_view.dart';
import 'package:zenith/widgets/timeline/award_stack.dart';

void main() {
  testWidgets('uses fallback icon in widget tests and preserves semantics', (
    tester,
  ) async {
    const award = Award(
      title: 'First Workout',
      icon: Icons.check_circle,
      modelAsset: 'assets/achievements/achievement_medal.glb',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AchievementModelView(award: award, size: 64)),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AchievementModelView)),
      matchesSemantics(label: 'First Workout'),
    );
  });
}
