import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/main_dock_spacer.dart';

void main() {
  testWidgets('MainDockSpacer includes safe area and clearance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: 12)),
          child: Scaffold(body: MainDockSpacer()),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MainDockSpacer));

    expect(size.height, AppTheme.mainDockClearance + 12);
  });

  testWidgets('MainDockSpacer adds extra space when requested', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: 10)),
          child: Scaffold(body: MainDockSpacer(extraSpace: 8)),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MainDockSpacer));

    expect(size.height, AppTheme.mainDockClearance + 18);
  });
}
