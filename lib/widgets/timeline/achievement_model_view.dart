import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
// ignore: implementation_imports
import 'package:flutter_3d_controller/src/core/modules/model_viewer/model_viewer.dart'
    as model_viewer;

import '../../theme/app_theme.dart';
import 'award_stack.dart';

// policy: allow-public-api primary widget for 3D/2D award display.
class AchievementModelView extends StatefulWidget {
  final Award award;
  final double size;
  final bool interactive;
  final bool startRotating;

  const AchievementModelView({
    super.key,
    required this.award,
    required this.size,
    this.interactive = false,
    this.startRotating = true,
  });

  @override
  State<AchievementModelView> createState() => _AchievementModelViewState();
}

class _AchievementModelViewState extends State<AchievementModelView> {
  static const Duration _recenterDelay = Duration(milliseconds: 900);
  static const Duration _recenterDuration = Duration(milliseconds: 9000);
  static const Duration _loadingFallbackDelay = Duration(seconds: 10);

  late Flutter3DController _controller;
  late final String _modalViewerId;
  bool _showFallback = _isWidgetTest;
  bool _isLoaded = _isWidgetTest;
  Timer? _loadingFallbackTimer;

  bool get _usesModalViewer => widget.interactive && !widget.startRotating;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
    _modalViewerId = 'achievement-model-${identityHashCode(this)}';
    _startLoadingFallbackTimer();
  }

  @override
  void didUpdateWidget(AchievementModelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.award.modelAsset != widget.award.modelAsset) {
      _loadingFallbackTimer?.cancel();
      _controller = Flutter3DController();
      _showFallback = _isWidgetTest;
      _isLoaded = _showFallback;
      _startLoadingFallbackTimer();
    }
  }

  @override
  void dispose() {
    _loadingFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewer = SizedBox(
      width: widget.size,
      height: widget.size,
      child: _showFallback
          ? _FallbackAwardIcon(award: widget.award)
          : _viewer(),
    );

    return Semantics(label: widget.award.title, child: viewer);
  }

  Widget _viewer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _usesModalViewer ? _modalViewer() : _standardViewer(),
        if (!_isLoaded)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
      ],
    );
  }

  // The package viewer uses camera orbit controls. In the achievement modal
  // this leaves downward/free roll rotation limited. Keep the package's native
  // gestures for stability. The recenter drift runs inside the web viewer so it
  // can ease from the actual camera position instead of an estimated Flutter
  // pointer offset.
  Widget _modalViewer() {
    return model_viewer.ModelViewer(
      src: widget.award.modelAsset,
      alt: widget.award.title,
      id: _modalViewerId,
      progressBarColor: context.appColors.transparent,
      cameraControls: true,
      disableTap: true,
      interactionPrompt: model_viewer.InteractionPrompt.none,
      cameraOrbit: _homeOrbit,
      interpolationDecay: 250,
      activeGestureInterceptor: true,
      debugLogging: false,
      relatedJs: _modalRecenterScript,
      onProgress: (progress) {
        if (progress >= 1) {
          _markModelLoaded();
        }
      },
      onLoad: (_) => _markModelLoaded(),
      onError: (_) => _showFallbackAward(),
    );
  }

  Widget _standardViewer() {
    return Flutter3DViewer(
      activeGestureInterceptor: widget.interactive,
      enableTouch: widget.interactive,
      progressBarColor: context.appColors.transparent,
      controller: _controller,
      src: widget.award.modelAsset,
      onProgress: (progress) {
        if (progress >= 1) {
          _markModelLoaded();
        }
      },
      onLoad: (_) {
        try {
          _controller.setCameraOrbit(
            widget.award.cameraTheta,
            widget.award.cameraPhi,
            widget.award.cameraRadius,
          );
          if (widget.startRotating) {
            _controller.startRotation(
              rotationSpeed: widget.award.rotationSpeed,
            );
          }
          _markModelLoaded();
        } catch (_) {
          _showFallbackAward();
        }
      },
      onError: (_) => _showFallbackAward(),
    );
  }

  String get _homeOrbit =>
      '${widget.award.cameraTheta}deg '
      '${widget.award.cameraPhi}deg '
      '${widget.award.cameraRadius}%';

  String get _modalRecenterScript {
    final homeTheta = widget.award.cameraTheta;
    final homePhi = widget.award.cameraPhi;
    final delayMs = _recenterDelay.inMilliseconds;
    final durationMs = _recenterDuration.inMilliseconds;

    return '''
(() => {
  const modelViewer = document.getElementById("$_modalViewerId");
  if (!modelViewer) return;

  const homeOrbit = "$_homeOrbit";
  const homeTheta = $homeTheta * Math.PI / 180;
  const homePhi = $homePhi * Math.PI / 180;
  const idleDelay = $delayMs;
  const duration = $durationMs;
  let idleTimer = null;
  let animationFrame = null;
  let listenersAttached = false;
  let loadNotified = false;

  const notifyFlutterLoaded = () => {
    if (loadNotified) return;
    loadNotified = true;

    const callLoadChannel = () => {
      const bridge = window.flutter_inappwebview;
      if (bridge && bridge.callHandler) {
        bridge.callHandler("onLoadChannel", "/model");
      } else {
        setTimeout(callLoadChannel, 50);
      }
    };

    callLoadChannel();
  };

  if (modelViewer.loaded) {
    notifyFlutterLoaded();
  } else {
    modelViewer.addEventListener("load", notifyFlutterLoaded, { once: true });
  }

  const stopDrift = () => {
    clearTimeout(idleTimer);
    if (animationFrame !== null) {
      cancelAnimationFrame(animationFrame);
      animationFrame = null;
    }
  };

  const clampPhi = (phi) => Math.min(Math.PI - 0.001, Math.max(0.001, phi));
  const smootherstep = (t) => t * t * t * (t * (t * 6 - 15) + 10);
  const shortestAngleDelta = (from, to) => {
    let delta = to - from;
    while (delta > Math.PI) delta -= Math.PI * 2;
    while (delta < -Math.PI) delta += Math.PI * 2;
    return delta;
  };

  const driftHome = () => {
    if (typeof modelViewer.getCameraOrbit !== "function") return;

    let start;
    try {
      start = modelViewer.getCameraOrbit();
    } catch (_) {
      return;
    }

    const startTheta = start.theta;
    const startPhi = start.phi;
    const startRadius = start.radius;
    const thetaDelta = shortestAngleDelta(startTheta, homeTheta);
    const phiDelta = homePhi - startPhi;
    const startTime = performance.now();

    const tick = (now) => {
      const progress = Math.min(1, (now - startTime) / duration);
      const eased = smootherstep(progress);
      const theta = startTheta + thetaDelta * eased;
      const phi = clampPhi(startPhi + phiDelta * eased);
      modelViewer.cameraOrbit = `\${theta}rad \${phi}rad \${startRadius}m`;

      if (progress < 1) {
        animationFrame = requestAnimationFrame(tick);
      } else {
        animationFrame = null;
        modelViewer.cameraOrbit = homeOrbit;
      }
    };

    animationFrame = requestAnimationFrame(tick);
  };

  const scheduleDrift = () => {
    stopDrift();
    idleTimer = setTimeout(driftHome, idleDelay);
  };

  const attachListeners = () => {
    if (listenersAttached) return;
    listenersAttached = true;
    modelViewer.addEventListener("pointerdown", stopDrift);
    modelViewer.addEventListener("pointerup", scheduleDrift);
    modelViewer.addEventListener("pointercancel", scheduleDrift);
    modelViewer.addEventListener("touchend", scheduleDrift);
    modelViewer.addEventListener("mouseup", scheduleDrift);
  };

  if (customElements && customElements.whenDefined) {
    customElements.whenDefined("model-viewer").then(attachListeners);
  } else {
    attachListeners();
  }
})();
''';
  }

  void _showFallbackAward() {
    _loadingFallbackTimer?.cancel();
    if (mounted) {
      setState(() {
        _showFallback = true;
        _isLoaded = true;
      });
    }
  }

  void _markModelLoaded() {
    _loadingFallbackTimer?.cancel();
    if (mounted && !_isLoaded) {
      setState(() => _isLoaded = true);
    }
  }

  void _startLoadingFallbackTimer() {
    if (_isLoaded) return;
    _loadingFallbackTimer = Timer(_loadingFallbackDelay, _markModelLoaded);
  }
}

class _FallbackAwardIcon extends StatelessWidget {
  final Award award;

  const _FallbackAwardIcon({required this.award});

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final color = award.color ?? scheme.primary;

    return Center(child: Icon(award.icon, color: color, size: 20));
  }
}

bool get _isWidgetTest {
  if (kIsWeb) {
    return false;
  }
  return WidgetsBinding.instance.runtimeType.toString().contains(
    'AutomatedTestWidgetsFlutterBinding',
  );
}
