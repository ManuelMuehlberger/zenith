import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/widgets/app_bottom_sheet.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
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
}
