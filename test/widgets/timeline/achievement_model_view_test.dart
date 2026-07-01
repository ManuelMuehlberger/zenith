import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/timeline/achievement_model_view.dart';
import 'package:zenith/widgets/timeline/award_stack.dart';

void main() {
  const award = Award(
    title: 'First Workout',
    icon: Icons.check_circle,
    modelAsset: 'assets/achievements/achievement_medal.glb',
  );

  test('configures opened models as upright yaw-only viewers', () {
    final attributes = AchievementModelView.debugModelViewerAttributes(
      award: award,
      interactive: true,
      startRotating: false,
    );

    expect(attributes['cameraOrbit'], '-24.0deg 90.0deg 2.7%');
    expect(attributes['orientation'], '0deg 90deg 0deg');
    expect(attributes['disableZoom'], 'true');
    expect(attributes['disablePan'], 'true');
    expect(attributes['minCameraOrbit'], '-150.0deg 90.0deg 2.7%');
    expect(attributes['maxCameraOrbit'], '150.0deg 90.0deg 2.7%');
    expect(attributes['backLockYawLimit'], '150.0');
  });

  test('keeps preview model configuration unchanged', () {
    final attributes = AchievementModelView.debugModelViewerAttributes(
      award: award,
      interactive: false,
      startRotating: true,
    );

    expect(attributes['cameraOrbit'], '35.0deg 70.0deg 2.7%');
    expect(attributes['orientation'], isNull);
    expect(attributes['disableZoom'], isNull);
    expect(attributes['disablePan'], isNull);
    expect(attributes['minCameraOrbit'], isNull);
    expect(attributes['maxCameraOrbit'], isNull);
    expect(attributes['backLockYawLimit'], isNull);
  });

  testWidgets('uses fallback icon in widget tests and preserves semantics', (
    tester,
  ) async {
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

  testWidgets('updates semantics when the displayed award changes', (
    tester,
  ) async {
    const firstAward = Award(
      title: 'First Workout',
      icon: Icons.check_circle,
      modelAsset: 'assets/achievements/achievement_medal.glb',
    );
    const secondAward = Award(
      title: 'Long Session',
      icon: Icons.timer_outlined,
      modelAsset: 'assets/achievements/achievement_medal.glb',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AchievementModelView(award: firstAward, size: 64)),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AchievementModelView(award: secondAward, size: 64),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AchievementModelView)),
      matchesSemantics(label: 'Long Session'),
    );
  });
}
