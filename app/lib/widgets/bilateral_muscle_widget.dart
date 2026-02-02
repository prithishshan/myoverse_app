import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/utils/svg_parser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BilateralMuscleWidget extends StatefulWidget {
  const BilateralMuscleWidget({
    super.key,
    required this.streams,
    required this.avgStreams,
    this.outlineAsset = 'assets/body_model/male/male_front_outline.svg',
    this.muscleAsset = 'assets/body_model/male/male_front_muscles.svg',
  });

  /// 12 streams: 0-5 (Left), 6-11 (Right)
  final List<Stream<double>> streams;

  /// 2 average streams: 0 (Left), 1 (Right)
  final List<Stream<double>> avgStreams;
  final String outlineAsset;
  final String muscleAsset;

  @override
  State<BilateralMuscleWidget> createState() => _BilateralMuscleWidgetState();
}

class _BilateralMuscleWidgetState extends State<BilateralMuscleWidget>
    with SingleTickerProviderStateMixin {
  // SVG Data
  bool _loaded = false;

  // Muscle Paths
  List<Path> _leftPaths = [];
  List<Path> _rightPaths = [];
  Rect _contentBounds = Rect.zero;

  // Stream Simulations
  final List<StreamSubscription> _subs = [];
  final List<double> _currents = List.filled(12, 0.0);
  final List<double> _targets = List.filled(12, 0.0);
  final List<double> _avgs = List.filled(2, 0.0); // 0: Left, 1: Right
  final List<double> _avgTargets = List.filled(2, 0.0);
  final SvgParser _parser = SvgParser();

  late AnimationController _controller;

  // Heatmap Positions (Normalized roughly to the muscle shape bounds)
  final List<Offset> _relativePositions = [
    // Anterior
    const Offset(0.3, 0.3),
    const Offset(0.4, 0.4),
    // Lateral
    const Offset(0.5, 0.5),
    const Offset(0.6, 0.4),
    // Posterior
    const Offset(0.7, 0.6),
    const Offset(0.5, 0.7),
  ];

  @override
  void initState() {
    super.initState();
    _loadSpecificSvg();
    _subscribeStreams();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_updateAnimation);
  }

  void _subscribeStreams() {
    // Heatmaps
    for (int i = 0; i < widget.streams.length; i++) {
      if (i < 12) {
        _subs.add(
          widget.streams[i].listen((val) {
            _targets[i] = val;
          }),
        );
      }
    }
    // Averages
    for (int i = 0; i < widget.avgStreams.length; i++) {
      if (i < 2) {
        _subs.add(
          widget.avgStreams[i].listen((val) {
            _avgTargets[i] = val;
          }),
        );
      }
    }
  }

  Future<void> _loadSpecificSvg() async {
    try {
      final data = await _parser.parseSpecificFromAsset(widget.muscleAsset, [
        'left_bicep_short',
        'left_bicep_long',
        'right_bicep_short',
        'right_bicep_long',
      ]);

      final left = data.parts
          .where((p) => p.id.startsWith('left'))
          .map((p) => p.path)
          .toList();
      final right = data.parts
          .where((p) => p.id.startsWith('right'))
          .map((p) => p.path)
          .toList();

      // Calculate bounds of the muscles to zoom in on them
      Rect bounds = Rect.zero;
      for (var p in left) {
        bounds = bounds == Rect.zero
            ? p.getBounds()
            : bounds.expandToInclude(p.getBounds());
      }
      for (var p in right) {
        bounds = bounds == Rect.zero
            ? p.getBounds()
            : bounds.expandToInclude(p.getBounds());
      }

      if (mounted) {
        setState(() {
          _leftPaths = left;
          _rightPaths = right;
          _contentBounds = bounds;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading Bilateral SVG: $e');
    }
  }

  void _updateAnimation() {
    if (!mounted) return;
    const double smoothing = 0.1;
    bool needsRepaint = false;

    // Smooth currents
    for (int i = 0; i < 12; i++) {
      final diff = _targets[i] - _currents[i];
      if (diff.abs() > 0.001) {
        _currents[i] += diff * smoothing;
        needsRepaint = true;
      }
    }

    // Smooth averages
    for (int i = 0; i < 2; i++) {
      final diff = _avgTargets[i] - _avgs[i];
      if (diff.abs() > 0.001) {
        _avgs[i] += diff * smoothing;
        needsRepaint = true;
      }
    }

    if (needsRepaint) setState(() {});
  }

  @override
  void dispose() {
    for (var sub in _subs) sub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // LEFT BAR
            _buildBar(_avgs[0]),

            // MUSCLE VIEW
            Expanded(
              child: CustomPaint(
                painter: BilateralMusclePainter(
                  leftPaths: _leftPaths,
                  rightPaths: _rightPaths,
                  contentBounds: _contentBounds,
                  intensities: _currents,
                  heatmapPoints: _relativePositions,
                ),
                size: Size.infinite,
              ),
            ),

            // RIGHT BAR
            _buildBar(_avgs[1]),
          ],
        );
      },
    );
  }

  Widget _buildBar(double value) {
    // Value 0.0 .. 1.0
    Color barColor;
    if (value < 0.5) {
      barColor = Color.lerp(Colors.yellow, Colors.orange, value * 2)!;
    } else {
      barColor = Color.lerp(Colors.orange, Colors.red, (value - 0.5) * 2)!;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: 24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [barColor.withOpacity(0.5), barColor],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class BilateralMusclePainter extends CustomPainter {
  BilateralMusclePainter({
    required this.leftPaths,
    required this.rightPaths,
    required this.contentBounds,
    required this.intensities,
    required this.heatmapPoints,
  });

  final List<Path> leftPaths;
  final List<Path> rightPaths;
  final Rect contentBounds;
  final List<double> intensities; // 0-5 Left, 6-11 Right
  final List<Offset> heatmapPoints; // 6 Normalized points

  @override
  void paint(Canvas canvas, Size size) {
    if (contentBounds.isEmpty) return;

    // Scale to fit contentBounds
    final double scaleX = size.width / contentBounds.width;
    final double scaleY = size.height / contentBounds.height;
    final double scale = math.min(scaleX, scaleY) * 0.9; // 90% fit

    final double dragX = size.width / 2 - contentBounds.center.dx * scale;
    final double dragY = size.height / 2 - contentBounds.center.dy * scale;

    canvas.save();
    canvas.translate(dragX, dragY);
    canvas.scale(scale, scale);

    // 1. Draw Left Paths
    _drawGroup(canvas, leftPaths, intensities.sublist(0, 6));

    // 2. Draw Right Paths
    _drawGroup(canvas, rightPaths, intensities.sublist(6, 12));

    canvas.restore();
  }

  void _drawGroup(Canvas canvas, List<Path> paths, List<double> values) {
    // 2.1 Draw Muscle Shape (Fill)
    final Paint musclePaint = Paint()
      ..color = Colors.grey[800]!
          .withOpacity(0.5) // Slightly brighter/transparent than background
      ..style = PaintingStyle.fill;

    // Combine for simpler bounds calc
    Rect groupBounds = Rect.zero;
    for (var p in paths) {
      canvas.drawPath(p, musclePaint);
      groupBounds = groupBounds == Rect.zero
          ? p.getBounds()
          : groupBounds.expandToInclude(p.getBounds());
    }

    // 2. Draw Heatmaps
    // Map normalized points to groupBounds
    for (int i = 0; i < heatmapPoints.length; i++) {
      if (i >= values.length) break;
      final double intensity = values[i];
      if (intensity <= 0.01) continue;

      final Offset norm = heatmapPoints[i];
      final double cx = groupBounds.left + norm.dx * groupBounds.width;
      final double cy = groupBounds.top + norm.dy * groupBounds.height;

      // Color
      Color color;
      if (intensity < 0.5) {
        final t = intensity * 2;
        color = Color.lerp(Colors.yellow, Colors.orange, t)!;
      } else {
        final t = (intensity - 0.5) * 2;
        color = Color.lerp(Colors.orange, Colors.red, t)!;
      }

      final double radius =
          groupBounds.width * 0.3; // Approx radius separate from view size

      final Paint paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [color.withOpacity(0.8 * intensity), color.withOpacity(0.0)],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    // 3. Draw Outline (on top of muscles for crisp edges)
    final Paint outlinePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Scaled relative to the view

    for (var p in paths) {
      canvas.drawPath(p, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BilateralMusclePainter oldDelegate) {
    return true;
  }
}
