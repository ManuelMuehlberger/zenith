import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
// ignore: implementation_imports
import 'package:flutter_3d_controller/src/core/modules/model_viewer/model_viewer.dart'
    as model_viewer;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../theme/app_theme.dart';
import 'award_stack.dart';

const double _modalHomeTheta = 0;
const double _modalHomePhi = 90;
const double _modalIntroThetaOffset = -24;
const double _modalYawLimit = 150;
const String _modalUprightOrientation = '0deg 90deg 0deg';

String _homeOrbitFor(Award award) =>
    '${award.cameraTheta}deg ${award.cameraPhi}deg ${award.cameraRadius}%';

String _modalHomeOrbitFor(Award award) =>
    '${_modalHomeTheta}deg ${_modalHomePhi}deg ${award.cameraRadius}%';

String _modalIntroOrbitFor(Award award) =>
    '${_modalHomeTheta + _modalIntroThetaOffset}deg '
    '${_modalHomePhi}deg '
    '${award.cameraRadius}%';

String _modalMinOrbitBoundsFor(Award award) =>
    '-${_modalYawLimit}deg ${_modalHomePhi}deg ${award.cameraRadius}%';

String _modalMaxOrbitBoundsFor(Award award) =>
    '${_modalYawLimit}deg ${_modalHomePhi}deg ${award.cameraRadius}%';

// policy: allow-public-api primary widget for 3D/2D award display.
class AchievementModelView extends StatefulWidget {
  final Award award;
  final double size;
  final bool interactive;
  final bool startRotating;
  final double? renderScale;

  const AchievementModelView({
    super.key,
    required this.award,
    required this.size,
    this.interactive = false,
    this.startRotating = true,
    this.renderScale,
  });

  @override
  State<AchievementModelView> createState() => _AchievementModelViewState();

  @visibleForTesting
  static Map<String, String?> debugModelViewerAttributes({
    required Award award,
    required bool interactive,
    required bool startRotating,
  }) {
    final useModalMode = interactive && !startRotating;
    return {
      'cameraOrbit': useModalMode
          ? _modalIntroOrbitFor(award)
          : _homeOrbitFor(award),
      'orientation': useModalMode ? _modalUprightOrientation : null,
      'disableZoom': useModalMode ? 'true' : null,
      'disablePan': useModalMode ? 'true' : null,
      'minCameraOrbit': useModalMode ? _modalMinOrbitBoundsFor(award) : null,
      'maxCameraOrbit': useModalMode ? _modalMaxOrbitBoundsFor(award) : null,
      'backLockYawLimit': useModalMode ? '$_modalYawLimit' : null,
    };
  }
}

class _AchievementModelViewState extends State<AchievementModelView> {
  static const Duration _modalBackReleaseDuration = Duration(milliseconds: 520);
  static const Duration _modalIntroDuration = Duration(milliseconds: 850);
  static const Duration _loadingFallbackDelay = Duration(seconds: 10);

  late Flutter3DController _controller;
  late final String _modalViewerId;
  String? _resolvedModelSrc;
  Future<String>? _embeddedHtml;
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
    unawaited(_resolveModelSrc());
  }

  @override
  void didUpdateWidget(AchievementModelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.award.modelAsset != widget.award.modelAsset) {
      _loadingFallbackTimer?.cancel();
      _controller = Flutter3DController();
      _resolvedModelSrc = null;
      _embeddedHtml = null;
      _showFallback = _isWidgetTest;
      _isLoaded = _showFallback;
      _startLoadingFallbackTimer();
      unawaited(_resolveModelSrc());
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
          : _scaledViewer(),
    );

    return Semantics(label: widget.award.title, child: viewer);
  }

  Widget _scaledViewer() {
    final scale = _effectiveRenderScale;
    if (scale >= 0.99) {
      return _viewer();
    }

    final renderSize = widget.size * scale;
    return Center(
      child: Transform.scale(
        scale: 1 / scale,
        child: SizedBox(
          key: const Key('achievement_model_low_res_viewport'),
          width: renderSize,
          height: renderSize,
          child: _viewer(),
        ),
      ),
    );
  }

  double get _effectiveRenderScale {
    final requestedScale =
        widget.renderScale ??
        (widget.interactive ? 1.0 : widget.award.previewRenderScale);
    return requestedScale.clamp(0.5, 1.0).toDouble();
  }

  Widget _viewer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_resolvedModelSrc != null && !kIsWeb && !_isWidgetTest)
          _embeddedViewer()
        else if (_resolvedModelSrc != null)
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

  Widget _embeddedViewer() {
    _embeddedHtml ??= _AchievementEmbeddedModelHtml.build(
      assetPath: _resolvedModelSrc!,
      viewerId: _modalViewerId,
      alt: widget.award.title,
      cameraOrbit: _effectiveInitialOrbit,
      cameraControls: widget.interactive,
      autoRotate: widget.startRotating,
      rotationSpeed: widget.award.rotationSpeed,
      disableZoom: _usesModalViewer,
      disablePan: _usesModalViewer,
      orientation: _usesModalViewer ? _modalUprightOrientation : null,
      minCameraOrbit: _usesModalViewer ? _modalMinOrbitBounds : null,
      maxCameraOrbit: _usesModalViewer ? _modalMaxOrbitBounds : null,
      relatedJs: _usesModalViewer ? _modalInteractionScript : null,
    );

    return FutureBuilder<String>(
      future: _embeddedHtml,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showFallbackAward();
          });
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return const SizedBox.expand();
        }

        return InAppWebView(
          initialData: InAppWebViewInitialData(
            data: snapshot.data!,
            mimeType: 'text/html',
            encoding: 'utf-8',
            baseUrl: WebUri('https://achievement-model.local/'),
          ),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            supportZoom: false,
            disableContextMenu: true,
          ),
          gestureRecognizers: widget.interactive
              ? const <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    EagerGestureRecognizer.new,
                  ),
                }
              : const <Factory<OneSequenceGestureRecognizer>>{},
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
              handlerName: 'onProgressChannel',
              callback: (args) {
                final progress = double.tryParse(args.first.toString()) ?? 0;
                if (progress >= 1) {
                  _markModelLoaded();
                }
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadChannel',
              callback: (_) => _markModelLoaded(),
            );
            controller.addJavaScriptHandler(
              handlerName: 'onErrorChannel',
              callback: (args) {
                debugPrint('achievement model error: ${args.join(', ')}');
                _showFallbackAward();
              },
            );
          },
          onReceivedError: (controller, request, error) {
            if (request.url.path == '/favicon.ico') {
              return;
            }
            debugPrint(
              'achievement webview error: '
              'main=${request.isForMainFrame} '
              'url=${request.url} '
              'type=${error.type} '
              'description=${error.description}',
            );
            if (request.isForMainFrame == true) {
              _showFallbackAward();
            }
          },
          onConsoleMessage: (_, message) {
            if (message.messageLevel == ConsoleMessageLevel.ERROR) {
              debugPrint('achievement model viewer: ${message.message}');
            }
          },
        );
      },
    );
  }

  // Keep the package's native orbit gestures for stability. The injected
  // script adds the modal-only intro motion and rear yaw lockout.
  Widget _modalViewer() {
    return model_viewer.ModelViewer(
      src: _resolvedModelSrc!,
      alt: widget.award.title,
      id: _modalViewerId,
      progressBarColor: context.appColors.transparent,
      cameraControls: true,
      disableZoom: true,
      disablePan: true,
      disableTap: true,
      interactionPrompt: model_viewer.InteractionPrompt.none,
      cameraOrbit: _modalIntroOrbit,
      minCameraOrbit: _modalMinOrbitBounds,
      maxCameraOrbit: _modalMaxOrbitBounds,
      orientation: _modalUprightOrientation,
      interpolationDecay: 250,
      activeGestureInterceptor: true,
      debugLogging: false,
      relatedJs: _modalInteractionScript,
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
      src: _resolvedModelSrc!,
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

  String get _homeOrbit => _homeOrbitFor(widget.award);

  String get _effectiveInitialOrbit =>
      _usesModalViewer ? _modalIntroOrbit : _homeOrbit;

  String get _modalHomeOrbit => _modalHomeOrbitFor(widget.award);

  String get _modalIntroOrbit => _modalIntroOrbitFor(widget.award);

  String get _modalMinOrbitBounds => _modalMinOrbitBoundsFor(widget.award);

  String get _modalMaxOrbitBounds => _modalMaxOrbitBoundsFor(widget.award);

  String get _modalInteractionScript {
    const homeTheta = _modalHomeTheta;
    const homePhi = _modalHomePhi;
    const yawLimit = _modalYawLimit;
    final releaseDurationMs = _modalBackReleaseDuration.inMilliseconds;
    final introDurationMs = _modalIntroDuration.inMilliseconds;

    return '''
(() => {
  const modelViewer = document.getElementById("$_modalViewerId");
  if (!modelViewer) return;

  const homeOrbit = "$_modalHomeOrbit";
  const homeTheta = $homeTheta * Math.PI / 180;
  const homePhi = $homePhi * Math.PI / 180;
  const yawLimit = $yawLimit * Math.PI / 180;
  const lockEpsilon = 0.5 * Math.PI / 180;
  const releaseDuration = $releaseDurationMs;
  const introDuration = $introDurationMs;
  let animationFrame = null;
  let listenersAttached = false;
  let loadNotified = false;
  let introPlayed = false;
  let isInteracting = false;
  let hitBackLock = false;
  let applyingGuard = false;

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

  const stopAnimation = () => {
    if (animationFrame !== null) {
      cancelAnimationFrame(animationFrame);
      animationFrame = null;
    }
  };

  const clampPhi = (phi) => Math.min(Math.PI - 0.001, Math.max(0.001, phi));
  const smootherstep = (t) => t * t * t * (t * (t * 6 - 15) + 10);
  const normalizeTheta = (theta) => {
    let normalized = theta - homeTheta;
    while (normalized > Math.PI) normalized -= Math.PI * 2;
    while (normalized < -Math.PI) normalized += Math.PI * 2;
    return normalized;
  };
  const shortestAngleDelta = (from, to) => {
    let delta = to - from;
    while (delta > Math.PI) delta -= Math.PI * 2;
    while (delta < -Math.PI) delta += Math.PI * 2;
    return delta;
  };

  const animateHome = (animationDuration) => {
    if (typeof modelViewer.getCameraOrbit !== "function") return;

    let start;
    try {
      start = modelViewer.getCameraOrbit();
    } catch (_) {
      return;
    }

    const startTheta = homeTheta + normalizeTheta(start.theta);
    const startPhi = start.phi;
    const startRadius = start.radius;
    const thetaDelta = shortestAngleDelta(startTheta, homeTheta);
    const phiDelta = homePhi - startPhi;
    const startTime = performance.now();

    const tick = (now) => {
      const progress = Math.min(1, (now - startTime) / animationDuration);
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

  const playIntro = () => {
    if (introPlayed) return;
    introPlayed = true;
    stopAnimation();
    animateHome(introDuration);
  };

  const handleLoad = () => {
    playIntro();
    notifyFlutterLoaded();
  };

  if (modelViewer.loaded) {
    handleLoad();
  } else {
    modelViewer.addEventListener("load", handleLoad, { once: true });
  }

  const applyBackLock = () => {
    if (applyingGuard || typeof modelViewer.getCameraOrbit !== "function") {
      return;
    }

    let orbit;
    try {
      orbit = modelViewer.getCameraOrbit();
    } catch (_) {
      return;
    }

    const theta = normalizeTheta(orbit.theta);
    if (Math.abs(theta) < yawLimit - lockEpsilon) return;

    hitBackLock = true;
    if (Math.abs(theta) <= yawLimit) return;

    const lockedTheta = homeTheta + Math.sign(theta) * yawLimit;
    applyingGuard = true;
    modelViewer.cameraOrbit = `\${lockedTheta}rad \${homePhi}rad \${orbit.radius}m`;
    requestAnimationFrame(() => {
      applyingGuard = false;
    });
  };

  const finishInteraction = () => {
    isInteracting = false;
    if (!hitBackLock) return;

    hitBackLock = false;
    stopAnimation();
    animateHome(releaseDuration);
  };

  const attachListeners = () => {
    if (listenersAttached) return;
    listenersAttached = true;
    modelViewer.addEventListener("pointerdown", () => {
      isInteracting = true;
      hitBackLock = false;
      stopAnimation();
    });
    modelViewer.addEventListener("camera-change", () => {
      if (isInteracting) applyBackLock();
    });
    modelViewer.addEventListener("pointerup", finishInteraction);
    modelViewer.addEventListener("pointercancel", finishInteraction);
    modelViewer.addEventListener("touchend", finishInteraction);
    modelViewer.addEventListener("mouseup", finishInteraction);
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

  Future<void> _resolveModelSrc() async {
    final requestedAsset = widget.award.modelAsset;

    if (mounted) {
      setState(() => _resolvedModelSrc = requestedAsset);
    }
  }
}

class _AchievementEmbeddedModelHtml {
  static Future<String>? _modelViewerScript;
  static final Map<String, Future<String>> _modelDataUris = {};

  static Future<String> build({
    required String assetPath,
    required String viewerId,
    required String alt,
    required String cameraOrbit,
    required bool cameraControls,
    required bool autoRotate,
    required int rotationSpeed,
    required bool disableZoom,
    required bool disablePan,
    String? orientation,
    String? minCameraOrbit,
    String? maxCameraOrbit,
    String? relatedJs,
  }) async {
    final script = await _loadModelViewerScript();
    final modelDataUri = await _loadModelDataUri(assetPath);
    final controls = cameraControls ? ' camera-controls' : '';
    final zoom = disableZoom ? ' disable-zoom' : '';
    final pan = disablePan ? ' disable-pan' : '';
    final orientationAttribute = orientation == null
        ? ''
        : ' orientation="${htmlEscape.convert(orientation)}"';
    final minOrbit = minCameraOrbit == null
        ? ''
        : ' min-camera-orbit="${htmlEscape.convert(minCameraOrbit)}"';
    final maxOrbit = maxCameraOrbit == null
        ? ''
        : ' max-camera-orbit="${htmlEscape.convert(maxCameraOrbit)}"';
    final rotation = autoRotate
        ? ' auto-rotate auto-rotate-delay="500" '
              'rotation-per-second="${rotationSpeed}deg"'
        : '';

    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="icon" href="data:," />
  <style>
    html, body, model-viewer {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: transparent;
      -webkit-touch-callout: none;
      -webkit-user-select: none;
      user-select: none;
      touch-action: none;
    }

    model-viewer::part(default-progress-bar) {
      display: none;
    }
  </style>
  <script type="module">
$script
  </script>
</head>
<body>
  <model-viewer
    id="${htmlEscape.convert(viewerId)}"
    src="${htmlEscape.convert(modelDataUri)}"
    alt="${htmlEscape.convert(alt)}"
    camera-orbit="${htmlEscape.convert(cameraOrbit)}"
    $minOrbit
    $maxOrbit
    $orientationAttribute
    interpolation-decay="250"
    interaction-prompt="none"
    disable-tap$controls$zoom$pan$rotation>
  </model-viewer>
  <script>
    (() => {
      const notify = (handler, value) => {
        const bridge = window.flutter_inappwebview;
        if (bridge && bridge.callHandler) {
          bridge.callHandler(handler, value);
        }
      };

      customElements.whenDefined("model-viewer").then(() => {
        const modelViewer = document.getElementById("${htmlEscape.convert(viewerId)}");
        if (!modelViewer) return;

        modelViewer.addEventListener("progress", (event) => {
          notify("onProgressChannel", event.detail.totalProgress || 0);
        });
        modelViewer.addEventListener("load", () => {
          notify("onProgressChannel", 1);
          notify("onLoadChannel", "/model");
        });
        modelViewer.addEventListener("error", (event) => {
          notify("onErrorChannel", event.detail ? JSON.stringify(event.detail) : "error");
        });

        if (modelViewer.loaded) {
          notify("onProgressChannel", 1);
          notify("onLoadChannel", "/model");
        }
      });
    })();
  </script>
  ${relatedJs == null ? '' : '<script>$relatedJs</script>'}
</body>
</html>
''';
  }

  static Future<String> _loadModelViewerScript() {
    return _modelViewerScript ??= rootBundle.loadString(
      'packages/flutter_3d_controller/assets/model_viewer.min.js',
    );
  }

  static Future<String> _loadModelDataUri(String assetPath) {
    return _modelDataUris.putIfAbsent(assetPath, () async {
      final bytes = await rootBundle.load(assetPath);
      final data = bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      return 'data:model/gltf-binary;base64,${base64Encode(data)}';
    });
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
