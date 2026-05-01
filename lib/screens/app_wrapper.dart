import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../main.dart';
import '../services/app_startup_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key, this.onboardingStatusLoader, this.bootstrapApp});

  final Future<bool> Function()? onboardingStatusLoader;
  final Future<void> Function()? bootstrapApp;

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

enum _AppWrapperStatePhase {
  checkingOnboarding,
  bootstrapping,
  onboarding,
  ready,
  error,
}

class _AppWrapperState extends State<AppWrapper> {
  static final Logger _logger = Logger('AppWrapper');
  _AppWrapperStatePhase _phase = _AppWrapperStatePhase.checkingOnboarding;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _logger.info('Initializing app wrapper');

    try {
      final onboardingStatusLoader =
          widget.onboardingStatusLoader ??
          UserService.instance.isOnboardingComplete;
      final isComplete = await onboardingStatusLoader();

      _logger.info('Onboarding status resolved: complete=$isComplete');

      if (!mounted) {
        _logger.fine('App wrapper unmounted before onboarding resolution');
        return;
      }

      if (!isComplete) {
        _logger.info('Routing user to onboarding flow');
        setState(() {
          _phase = _AppWrapperStatePhase.onboarding;
          _startupError = null;
        });
        return;
      }

      setState(() {
        _phase = _AppWrapperStatePhase.bootstrapping;
        _startupError = null;
      });

      _logger.info('Bootstrapping main application services');

      final bootstrapApp =
          widget.bootstrapApp ?? AppStartupService.instance.initializeMainApp;
      await bootstrapApp();

      if (!mounted) {
        _logger.fine('App wrapper unmounted before bootstrap completion');
        return;
      }

      setState(() {
        _phase = _AppWrapperStatePhase.ready;
      });

      _logger.info('App wrapper initialization completed successfully');
    } catch (error, stackTrace) {
      _logger.severe('App wrapper initialization failed', error, stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _phase = _AppWrapperStatePhase.error;
        _startupError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _AppWrapperStatePhase.checkingOnboarding:
        return const _AppLoadingScreen(message: 'Checking your setup...');
      case _AppWrapperStatePhase.bootstrapping:
        return const _AppLoadingScreen(
          message: 'Preparing your workout data...',
        );
      case _AppWrapperStatePhase.onboarding:
        return const OnboardingScreen();
      case _AppWrapperStatePhase.ready:
        return const MainScreen();
      case _AppWrapperStatePhase.error:
        return _AppStartupErrorScreen(
          error: _startupError,
          onRetry: _initializeApp,
        );
    }
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppStartupErrorScreen extends StatelessWidget {
  const _AppStartupErrorScreen({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;

    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The app could not finish starting up.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                error?.toString() ?? 'Unknown startup error',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
