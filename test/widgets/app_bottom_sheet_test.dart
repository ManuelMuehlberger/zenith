import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/app_bottom_sheet.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('AppBottomSheet applies sheet radius and bottom inset padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomSheet(
              child: SizedBox(height: 40, child: Text('sheet content')),
            ),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppBottomSheet),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(
      decoration.borderRadius,
      const BorderRadius.vertical(
        top: Radius.circular(AppConstants.SHEET_RADIUS),
      ),
    );

    final paddings = tester
        .widgetList<Padding>(
          find.descendant(
            of: find.byType(AppBottomSheet),
            matching: find.byType(Padding),
          ),
        )
        .toList();
    expect(
      paddings.any(
        (padding) =>
            padding.padding == const EdgeInsets.fromLTRB(16, 10, 16, 36),
      ),
      isTrue,
    );
  });

  testWidgets('showAppBottomSheet presents the provided sheet content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppBottomSheet<void>(
              context: context,
              builder: (_) => const AppBottomSheet(
                child: SizedBox(height: 40, child: Text('modal content')),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.text('modal content'), findsOneWidget);
  });
}
