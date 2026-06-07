import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/timeline/award_stack.dart';

void main() {
  testWidgets('renders up to three visible awards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AwardStack(
            awards: List.generate(
              4,
              (index) => Award(
                title: 'Award $index',
                icon: Icons.star,
                modelAsset: 'assets/achievements/model.glb',
                thumbnailAsset: 'assets/achievements/full.png',
                compactThumbnailAsset: 'assets/achievements/compact.png',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AwardStack), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
  });

  testWidgets('does not build anything for an empty award list', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AwardStack(awards: [])),
      ),
    );

    expect(find.byType(AwardStack), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
