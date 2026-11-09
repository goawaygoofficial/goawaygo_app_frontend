import 'package:app_frontend/core/i18n/i18n.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// Shown until the destination page is completely ready (the AI needs 10-20 s): a plane circling a turning globe,
/// with changing travel messages (the website's `TravelLoader`). Still when the system asks for less motion; only
/// the messages change.
class TravelLoader extends StatefulWidget {
  const TravelLoader({super.key, required this.place});

  final String place;

  @override
  State<TravelLoader> createState() => _TravelLoaderState();
}

class _TravelLoaderState extends State<TravelLoader>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    'Packing your bags…',
    'Checking the entry rules…',
    'Finding the best views…',
    'Asking locals where to eat…',
    'Working out how to get around…',
    'Picking the best areas to stay…',
    'Almost ready for take-off…',
  ];

  /// One lap of the plane; the globe turns once every two laps.
  late final AnimationController _lap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  Timer? _messageTimer;
  int _message = 0;

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (_message < _messages.length - 1) setState(() => _message++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _lap.stop();
    } else if (!_lap.isAnimating) {
      _lap.repeat();
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _lap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: tr('Getting {0} ready. This can take up to a minute.', [
        widget.place,
      ]),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 190,
              child: AnimatedBuilder(
                animation: _lap,
                builder: (context, _) {
                  final angle = _lap.value * 2 * math.pi;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(190),
                        painter: _GlobePainter(turn: _lap.value),
                      ),
                      // The plane on the dashed orbit, nose pointing the way it flies (clockwise).
                      Transform.rotate(
                        angle: angle,
                        child: const Align(
                          alignment: Alignment.topCenter,
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Icon(
                              Icons.flight,
                              size: 34,
                              color: ColorsUtil.whiteColor,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black26),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.place.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                tr(_messages[_message]),
                key: ValueKey(_message),
                style: TextStyle(
                  color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A globe whose land slides sideways (looks like it is turning), a soft light from the top left, and a
/// dashed orbit around it.
class _GlobePainter extends CustomPainter {
  _GlobePainter({required this.turn});

  /// 0..1 through one lap of the plane.
  final double turn;

  /// Blobs of land as (x, y, width, height) in a 100-unit-wide strip that repeats around the globe.
  static const _land = [
    Rect.fromLTWH(8, 28, 26, 18),
    Rect.fromLTWH(38, 52, 18, 20),
    Rect.fromLTWH(60, 24, 14, 12),
    Rect.fromLTWH(70, 62, 10, 9),
    Rect.fromLTWH(18, 66, 12, 10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.32;
    // The plane icon (34 px) sits at the top of the box, so its centre is 17 px in.
    final orbitRadius = size.width * 0.5 - 17;
    final globe = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, Paint()..color = ColorsUtil.primaryLight);

    canvas.save();
    canvas.clipPath(Path()..addOval(globe));
    final scale = radius * 2 / 100;
    // Half a strip per lap: the globe turns slower than the plane flies.
    final shift = (turn * 50) * scale;
    final landPaint = Paint()..color = ColorsUtil.secondaryLight;
    for (final copy in [0.0, 100.0]) {
      for (final blob in _land) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              globe.left + (blob.left + copy) * scale - shift,
              globe.top + blob.top * scale,
              blob.width * scale,
              blob.height * scale,
            ),
            Radius.circular(blob.height * scale / 2),
          ),
          landPaint,
        );
      }
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.25),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(globe),
    );
    canvas.restore();

    // Dashed orbit.
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dashes = 48;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbitRadius),
        start,
        math.pi / dashes,
        false,
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(_GlobePainter oldDelegate) => oldDelegate.turn != turn;
}
