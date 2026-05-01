import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../profile_icon_button.dart';

class HomeScreenSliverAppBar extends StatelessWidget {
  final bool showGreetingTitle;

  const HomeScreenSliverAppBar({super.key, required this.showGreetingTitle});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: const SizedBox(width: kToolbarHeight),
      backgroundColor: context.appColors.overlayStrong.withValues(alpha: 0),
      elevation: 0,
      expandedHeight: kToolbarHeight + 60.0,
      actions: const [ProfileIconButton()],
      flexibleSpace: LayoutBuilder(
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: ColoredBox(color: context.appColors.overlayStrong),
                ),
              ),
              FlexibleSpaceBar(
                centerTitle: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HomeScreenTitle(
                      isLarge: false,
                      showGreetingTitle: showGreetingTitle,
                    ),
                  ],
                ),
                background: Align(
                  alignment: Alignment.center,
                  child: _HomeScreenTitle(
                    isLarge: true,
                    showGreetingTitle: showGreetingTitle,
                  ),
                ),
                collapseMode: CollapseMode.parallax,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeScreenTitle extends StatelessWidget {
  final bool isLarge;
  final bool showGreetingTitle;

  const _HomeScreenTitle({
    required this.isLarge,
    required this.showGreetingTitle,
  });

  @override
  Widget build(BuildContext context) {
    final style = isLarge
        ? context.appText.displaySmall!
        : context.appText.titleLarge!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        if (isLarge) {
          return FadeTransition(opacity: animation, child: child);
        }
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: showGreetingTitle
          ? AnimatedBuilder(
              key: ValueKey(
                isLarge ? 'large_greeting_title' : 'greeting_title',
              ),
              animation: UserService.instance,
              builder: (context, _) {
                final name = UserService.instance.currentProfile?.name.trim();
                final greeting = name != null && name.isNotEmpty
                    ? 'Hey, $name!'
                    : 'Hey!';
                return Text(
                  greeting,
                  textAlign: TextAlign.center,
                  style: style,
                );
              },
            )
          : Text(
              'Recent Workouts',
              key: ValueKey(isLarge ? 'large_recent_title' : 'recent_title'),
              textAlign: TextAlign.center,
              style: style,
            ),
    );
  }
}
