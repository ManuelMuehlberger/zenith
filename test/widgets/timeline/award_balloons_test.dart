import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/timeline/award_balloons.dart';
import 'package:zenith/widgets/timeline/award_stack.dart';

void main() {
  testWidgets('shows overflow count as remaining awards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AwardBalloons(
            awards: List.generate(
              5,
              (index) => Award(
                title: 'Award $index',
                icon: Icons.star,
                modelAsset: 'missing.glb',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('+2'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });
}
