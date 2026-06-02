import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/home/home_screen_sliver_app_bar.dart';

void main() {
  testWidgets(
    'HomeScreenSliverAppBar shows the default title when greeting is hidden',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                HomeScreenSliverAppBar(showGreetingTitle: false),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Recent Workouts'), findsOneWidget);
    },
  );
}
