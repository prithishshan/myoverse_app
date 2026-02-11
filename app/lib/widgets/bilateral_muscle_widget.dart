import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/models/muscle_part.dart';

class BilateralMuscleWidget extends StatefulWidget {
  const BilateralMuscleWidget({
    super.key,
    required this.streams,
    required this.avgStreams,
    required this.leftMuscleGroup,
    required this.rightMuscleGroup,
  });

  /// 12 streams: 0-5 (Left), 6-11 (Right)
  final List<Stream<double>> streams;

  /// 2 average streams: 0 (Left), 1 (Right)
  final List<Stream<double>> avgStreams;

  /// Left muscle group data
  final MuscleGroup leftMuscleGroup;

  /// Right muscle group data
  final MuscleGroup rightMuscleGroup;

  @override
  State<BilateralMuscleWidget> createState() => _BilateralMuscleWidgetState();
}

class _BilateralMuscleWidgetState extends State<BilateralMuscleWidget>
    with SingleTickerProviderStateMixin {
  bool _loaded = false;

  List<Path> _leftPaths = [];
  List<Path> _rightPaths = [];
  Rect _contentBounds = Rect.zero;

  final List<StreamSubscription> _subs = [];
  final List<double> _currents = List.filled(12, 0.0);
  final List<double> _targets = List.filled(12, 0.0);
  final List<double> _avgs = List.filled(2, 0.0);
  final List<double> _avgTargets = List.filled(2, 0.0);

  late AnimationController _controller;

  // Heatmap Positions (Normalized to muscle shape bounds)
  final List<Offset> _relativePositions = [
    const Offset(0.3, 0.3),
    const Offset(0.4, 0.4),
    const Offset(0.5, 0.5),
    const Offset(0.6, 0.4),
    const Offset(0.7, 0.6),
    const Offset(0.5, 0.7),
  ];

  @override
  void initState() {
    super.initState();
    _loadMuscleData();
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

  void _loadMuscleData() {
    try {
      // Extract paths from injected muscle groups
      final left = widget.leftMuscleGroup.parts.map((p) => p.path).toList();
      final right = widget.rightMuscleGroup.parts.map((p) => p.path).toList();

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
      debugPrint('Error loading Bilateral muscle data: $e');
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
  void didUpdateWidget(covariant BilateralMuscleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leftMuscleGroup.id != widget.leftMuscleGroup.id ||
        oldWidget.rightMuscleGroup.id != widget.rightMuscleGroup.id) {
      _loaded = false;
      _loadMuscleData();
    }
    if (oldWidget.streams != widget.streams ||
        oldWidget.avgStreams != widget.avgStreams) {
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
    if (!_loaded) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            _buildBar(_avgs[0]),
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
            _buildBar(_avgs[1]),
          ],
        );
      },
    );
  }

  Widget _buildBar(double value) {
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
                    colors: [barColor.withValues(alpha: 0.5), barColor],
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
  final List<double> intensities;
  final List<Offset> heatmapPoints;

  @override
  void paint(Canvas canvas, Size size) {
    if (contentBounds.isEmpty) return;

    final double scaleX = size.width / contentBounds.width;
    final double scaleY = size.height / contentBounds.height;
    final double scale = math.min(scaleX, scaleY) * 0.9;

    final double dragX = size.width / 2 - contentBounds.center.dx * scale;
    final double dragY = size.height / 2 - contentBounds.center.dy * scale;

    canvas.save();
    canvas.translate(dragX, dragY);
    canvas.scale(scale, scale);

    _drawGroup(canvas, leftPaths, intensities.sublist(0, 6));
    _drawGroup(canvas, rightPaths, intensities.sublist(6, 12));

    canvas.restore();
  }

  void _drawGroup(Canvas canvas, List<Path> paths, List<double> values) {
    final Paint musclePaint = Paint()
      ..color = Colors.grey[800]!.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    Rect groupBounds = Rect.zero;
    for (var p in paths) {
      canvas.drawPath(p, musclePaint);
      groupBounds = groupBounds == Rect.zero
          ? p.getBounds()
          : groupBounds.expandToInclude(p.getBounds());
    }

    // Draw Heatmaps
    for (int i = 0; i < heatmapPoints.length; i++) {
      if (i >= values.length) break;
      final double intensity = values[i];
      if (intensity <= 0.01) continue;

      final Offset norm = heatmapPoints[i];
      final double cx = groupBounds.left + norm.dx * groupBounds.width;
      final double cy = groupBounds.top + norm.dy * groupBounds.height;

      Color color;
      if (intensity < 0.5) {
        final t = intensity * 2;
        color = Color.lerp(Colors.yellow, Colors.orange, t)!;
      } else {
        final t = (intensity - 0.5) * 2;
        color = Color.lerp(Colors.orange, Colors.red, t)!;
      }

      final double radius = groupBounds.width * 0.3;

      final Paint paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [
            color.withValues(alpha: 0.8 * intensity),
            color.withValues(alpha: 0.0),
          ],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    // Draw Outline
    final Paint outlinePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var p in paths) {
      canvas.drawPath(p, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BilateralMusclePainter oldDelegate) {
    return true;
  }
}
