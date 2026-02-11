import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/models/muscle_part.dart';

class MuscleWidget extends StatefulWidget {
  const MuscleWidget({
    super.key,
    required this.streams,
    required this.muscleGroup,
    this.avgStreams = const [],
    this.showRings = true,
  });

  /// 6 separate streams of intensities (0.0 .. 1.0) for heatmap
  final List<Stream<double>> streams;

  /// 3 averaged streams (0.0 .. 1.0) for activity rings
  final List<Stream<double>> avgStreams;

  /// The muscle group object containing paths and metadata
  final MuscleGroup muscleGroup;

  /// Whether to show the activity rings
  final bool showRings;

  @override
  State<MuscleWidget> createState() => _MuscleWidgetState();
}

class _MuscleWidgetState extends State<MuscleWidget>
    with SingleTickerProviderStateMixin {
  // SVG Part Support
  Path? _musclePath;
  Size? _svgSize;
  bool _svgLoaded = false;

  final List<StreamSubscription<double>> _subs = [];

  // Heatmap values
  final List<double> _targets = List.filled(6, 0.0);
  final List<double> _currents = List.filled(6, 0.0);

  // Ring values
  final List<double> _avgTargets = List.filled(3, 0.0);
  final List<double> _avgCurrents = List.filled(3, 0.0);

  // Reps counting
  int _reps = 0;
  double _lastAvg = 0.0;

  // Rolling Average History (timestamp, value)
  final List<(int, double)> _history = [];
  double _rollingAvgDisplay = 0.0;

  late AnimationController _controller;

  // Fixed positions for the 6 heatmap points
  // Mapped to: Anterior (0,1), Lateral (2,3), Posterior (4,5)
  final List<Offset> _positions = [
    // Anterior Deltoid (Front/Left area)
    const Offset(0.25, 0.4),
    const Offset(0.35, 0.5),
    // Lateral Deltoid (Middle area)
    const Offset(0.5, 0.3),
    const Offset(0.5, 0.5),
    // Posterior Deltoid (Back/Right area)
    const Offset(0.65, 0.4),
    const Offset(0.6, 0.5),
  ];

  @override
  void initState() {
    super.initState();
    _loadSvgPath();
    _subscribeStreams();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_updateAnimation);
  }

  void _subscribeStreams() {
    // Subscribe to heatmap streams
    for (int i = 0; i < widget.streams.length; i++) {
      if (i < 6) {
        _subs.add(
          widget.streams[i].listen((val) {
            _targets[i] = val;
          }),
        );
      }
    }
    // Subscribe to ring streams
    for (int i = 0; i < widget.avgStreams.length; i++) {
      if (i < 3) {
        _subs.add(
          widget.avgStreams[i].listen((val) {
            _avgTargets[i] = val;
          }),
        );
      }
    }
  }

  void _loadSvgPath() {
    try {
      if (widget.muscleGroup.parts.isEmpty) {
        debugPrint("MuscleWidget: No muscle parts available");
        return;
      }

      // Combine all parts from the injected muscle group into a single path
      final combinedPath = Path();
      for (var part in widget.muscleGroup.parts) {
        combinedPath.addPath(part.path, Offset.zero);
      }

      // Calculate size from the path bounds
      final bounds = combinedPath.getBounds();

      if (mounted) {
        setState(() {
          _musclePath = combinedPath;
          _svgSize = Size(bounds.right, bounds.bottom);
          _svgLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading SVG path: $e");
    }
  }

  void _updateAnimation() {
    if (!mounted) return;

    const double smoothing = 0.1;
    bool needsRepaint = false;
    final int now = DateTime.now().millisecondsSinceEpoch;

    // Heatmap smoothing
    for (int i = 0; i < 6; i++) {
      final diff = _targets[i] - _currents[i];
      if (diff.abs() > 0.001) {
        _currents[i] += diff * smoothing;
        needsRepaint = true;
      }
    }

    // Calculate Global Average from smoothed currents
    double sum = 0;
    for (var val in _currents) {
      sum += val;
    }
    final double globalAvg = sum / 6.0;

    if ((_avgCurrents[0] - globalAvg).abs() > 0.001) {
      _avgCurrents[0] = globalAvg;
      needsRepaint = true;
    }

    // Rolling Average (5s window)
    _history.add((now, globalAvg));
    _history.removeWhere((item) => now - item.$1 > 5000);

    if (_history.isNotEmpty) {
      double total = 0;
      for (var item in _history) {
        total += item.$2;
      }
      final double newRolling = total / _history.length;

      if ((_rollingAvgDisplay - newRolling).abs() > 0.01) {
        _rollingAvgDisplay = newRolling;
        needsRepaint = true;
      }
    } else {
      _rollingAvgDisplay = 0.0;
    }

    // Reps Logic: Increment if current average crosses 0.4 threshold from below
    if (_lastAvg < 0.4 && _avgCurrents[0] >= 0.4) {
      _reps++;
      needsRepaint = true;
    }
    _lastAvg = _avgCurrents[0];

    if (needsRepaint) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MuscleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streams != widget.streams ||
        oldWidget.avgStreams != widget.avgStreams ||
        oldWidget.muscleGroup.id != widget.muscleGroup.id) {
      if (oldWidget.muscleGroup.id != widget.muscleGroup.id) {
        _svgLoaded = false;
        _loadSvgPath();
      }
      for (var sub in _subs) {
        sub.cancel();
      }
      _subs.clear();
      _subscribeStreams();
    }
  }

  @override
  void dispose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_svgLoaded || _musclePath == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              painter: MusclePainter(
                musclePath: _musclePath,
                svgSize: _svgSize,
                points: _positions,
                intensities: _currents,
                ringValues: _avgCurrents,
                showRings: widget.showRings,
              ),
              size: Size(size, size),
            ),
            // Left: Intensity Percentage
            Positioned(
              bottom: -40,
              left: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${(_rollingAvgDisplay * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Avg Intensity',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Right: Reps Counter
            Positioned(
              bottom: -40,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_reps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Repetitions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class MusclePainter extends CustomPainter {
  MusclePainter({
    this.musclePath,
    this.svgSize,
    required this.points,
    required this.intensities,
    required this.ringValues,
    required this.showRings,
  });

  final Path? musclePath;
  final Size? svgSize;
  final List<Offset> points;
  final List<double> intensities;
  final List<double> ringValues;
  final bool showRings;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    final imageRadius = maxRadius * 0.70;

    canvas.save();

    final imageRect = Rect.fromCircle(center: center, radius: imageRadius);
    canvas.clipPath(Path()..addOval(imageRect));
    canvas.drawPaint(Paint()..color = Colors.black);

    Rect contentBoundingBox = imageRect;

    if (musclePath != null && svgSize != null) {
      final Rect pathBounds = musclePath!.getBounds();
      final double scaleX = imageRect.width / pathBounds.width;
      final double scaleY = imageRect.height / pathBounds.height;
      final double scale = math.min(scaleX, scaleY) * 0.9;

      final double dragX = imageRect.center.dx - pathBounds.center.dx * scale;
      final double dragY = imageRect.center.dy - pathBounds.center.dy * scale;

      canvas.translate(dragX, dragY);
      canvas.scale(scale, scale);

      final Paint musclePaint = Paint()..style = PaintingStyle.fill;
      final Color baseColor = Colors.grey[800]!;

      final Gradient gradient = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [
          baseColor.withValues(alpha: 0.8),
          baseColor,
          Colors.grey[900]!,
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      musclePaint.shader = gradient.createShader(pathBounds);
      canvas.drawPath(musclePath!, musclePaint);
      contentBoundingBox = pathBounds;
    }

    // Draw Heatmaps
    for (int i = 0; i < points.length; i++) {
      if (i >= intensities.length) break;

      final double intensity = intensities[i];
      final Offset normPos = points[i];

      final double cx =
          contentBoundingBox.left + normPos.dx * contentBoundingBox.width;
      final double cy =
          contentBoundingBox.top + normPos.dy * contentBoundingBox.height;

      Color color;
      if (intensity < 0.5) {
        final t = intensity * 2;
        color = Color.lerp(Colors.yellow, Colors.orange, t)!;
      } else {
        final t = (intensity - 0.5) * 2;
        color = Color.lerp(Colors.orange, Colors.red, t)!;
      }

      double radius = contentBoundingBox.width * 0.25;

      final Paint paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [
            color.withValues(alpha: 0.9 * intensity),
            color.withValues(alpha: 0.0),
          ],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    canvas.restore();

    // Draw Rings
    if (showRings && ringValues.isNotEmpty) {
      final double value = ringValues[0].clamp(0.0, 1.0);

      final double ringStrokeWidth = (maxRadius - imageRadius) * 0.3;
      final double ringRadius = imageRadius + (maxRadius - imageRadius) * 0.5;

      Color ringColor;
      if (value < 0.5) {
        ringColor = Color.lerp(Colors.yellow, Colors.orange, value * 2)!;
      } else {
        ringColor = Color.lerp(Colors.orange, Colors.red, (value - 0.5) * 2)!;
      }

      final Paint ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStrokeWidth
        ..color = ringColor
        ..strokeCap = StrokeCap.round;

      final Paint trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStrokeWidth
        ..color = Colors.grey[800]!
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, ringRadius, trackPaint);

      const double maxSweep = 2 * math.pi;
      final double sweepAngle = maxSweep * value;
      final double startAngle = (math.pi / 2) - (sweepAngle / 2);

      if (value > 0.01) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: ringRadius),
          startAngle,
          sweepAngle,
          false,
          ringPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MusclePainter oldDelegate) {
    return true;
  }
}
