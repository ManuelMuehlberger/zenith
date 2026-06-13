import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/app_bottom_sheet.dart';
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

  testWidgets('prefers compact thumbnail assets for small stacked chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AwardBalloons(
            awards: [
              Award(
                title: 'Compact',
                icon: Icons.star,
                modelAsset: 'missing.glb',
                thumbnailAsset: 'assets/achievements/full.png',
                compactThumbnailAsset: 'assets/achievements/compact.png',
              ),
            ],
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'assets/achievements/compact.png');
  });

  testWidgets('opens reusable app bottom sheet for award details', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AwardBalloons(
            awards: [
              Award(
                title: 'Long Session',
                reason: 'You trained longer than usual.',
                icon: Icons.timer_outlined,
                modelAsset: 'missing.glb',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Long Session'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.text('Long Session'), findsWidgets);
  });
}
