import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MuscleWidget extends StatefulWidget {
  const MuscleWidget({
    super.key,
    required this.streams,
    this.avgStreams = const [],
    this.imageAsset = 'assets/body_model/shoulder.png',
    this.showRings = true,
  });

  /// 6 separate streams of intensities (0.0 .. 1.0) for heatmap
  final List<Stream<double>> streams;

  /// 3 averaged streams (0.0 .. 1.0) for activity rings
  final List<Stream<double>> avgStreams;

  /// Asset path for the muscle image
  final String imageAsset;

  /// Whether to show the activity rings
  final bool showRings;

  @override
  State<MuscleWidget> createState() => _MuscleWidgetState();
}

class _MuscleWidgetState extends State<MuscleWidget>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  bool _imageLoaded = false;

  final List<StreamSubscription<double>> _subs = [];

  // Heatmap values
  final List<double> _targets = List.filled(6, 0.0);
  final List<double> _currents = List.filled(6, 0.0);

  // Ring values
  final List<double> _avgTargets = List.filled(3, 0.0);
  final List<double> _avgCurrents = List.filled(3, 0.0);

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
    _loadImage();
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

  Future<void> _loadImage() async {
    try {
      final ByteData data = await rootBundle.load(widget.imageAsset);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _image = fi.image;
          _imageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading muscle image: $e");
    }
  }

  void _updateAnimation() {
    if (!mounted) return;

    const double smoothing = 0.1;
    bool needsRepaint = false;

    // Heatmap smoothing
    for (int i = 0; i < 6; i++) {
      final diff = _targets[i] - _currents[i];
      if (diff.abs() > 0.001) {
        _currents[i] += diff * smoothing;
        needsRepaint = true;
      }
    }

    // Ring smoothing
    for (int i = 0; i < 3; i++) {
      final diff = _avgTargets[i] - _avgCurrents[i];
      if (diff.abs() > 0.001) {
        _avgCurrents[i] += diff * smoothing;
        needsRepaint = true;
      }
    }

    if (needsRepaint) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MuscleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    if (!_imageLoaded || _image == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use minimum dimension to ensure circles
        final double size = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return CustomPaint(
          painter: MusclePainter(
            image: _image!,
            points: _positions,
            intensities: _currents,
            ringValues: _avgCurrents,
            showRings: widget.showRings,
          ),
          size: Size(size, size),
        );
      },
    );
  }
}

class MusclePainter extends CustomPainter {
  MusclePainter({
    required this.image,
    required this.points,
    required this.intensities,
    required this.ringValues,
    required this.showRings,
  });

  final ui.Image image;
  final List<Offset> points;
  final List<double> intensities;
  final List<double> ringValues;
  final bool showRings;

  // Cool colors for rings: Cyan, Blue, Purple
  // Colors: Anterior (Magenta), Lateral (Purple), Posterior (Cyan)
  static const List<Color> ringColors = [
    Color(0xFFFF4081), // Magenta (Anterior)
    Color(0xFF9C27B0), // Purple (Lateral)
    Color(0xFF00E5FF), // Cyan (Posterior)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate layout
    // We want the image in the center, masked to a circle.
    // The rings wrap around the outside of the image.
    // Let's allocate 15% of radius for rings.

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    final imageRadius = maxRadius * 0.70; // Image takes 70%

    // Draw Image Masked
    canvas.save();

    final imageRect = Rect.fromCircle(center: center, radius: imageRadius);
    canvas.clipPath(Path()..addOval(imageRect));

    // Fill background with black just in case image has transparency
    canvas.drawPaint(Paint()..color = Colors.black);

    // Draw Image (Cover)
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final FittedSizes fitted = applyBoxFit(
      BoxFit.cover,
      src.size,
      imageRect.size,
    );
    final Rect inputRect = Alignment.center.inscribe(fitted.source, src);
    final Rect outputRect = Alignment.center.inscribe(
      fitted.destination,
      imageRect,
    );

    canvas.drawImageRect(image, inputRect, outputRect, Paint());

    // Draw Masked Tints (Coloring muscle straps)
    // Use srcATop to draw colors ONLY where the underlying image is opaque.

    // Draw Heatmaps (Transformed to outputRect)
    for (int i = 0; i < points.length; i++) {
      if (i >= intensities.length) break;

      final double intensity = intensities[i];
      final Offset normPos = points[i];

      // Map normalized 0..1 to the image rect coordinates
      // The image behaves as cover, so we need to be careful if aspect ratio differs.
      // Assuming square image asset or similar aspect, but Cover logic applies.
      // Let's approximate by mapping to the full imageRect for now.
      final double cx = outputRect.left + normPos.dx * outputRect.width;
      final double cy = outputRect.top + normPos.dy * outputRect.height;

      final double radius = imageRadius * 0.35; // Increased radius

      // Yellow -> Orange -> Red
      Color color;
      if (intensity < 0.5) {
        final t = intensity * 2;
        color = Color.lerp(Colors.yellow, Colors.orange, t)!;
      } else {
        final t = (intensity - 0.5) * 2;
        color = Color.lerp(Colors.orange, Colors.red, t)!;
      }

      final Paint paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [
            color.withOpacity(0.9 * intensity),
            color.withOpacity(0.0),
          ], // Increased opacity
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
    canvas.restore(); // Remove clip

    // 2. Draw Rings
    // Starts at top (-pi/2). Counter-clockwise means negative angle sweep.
    // Rings should be thin lines.

    if (showRings) {
      // Ring 1 (Inner) -> Ring 3 (Outer)
      final double ringStrokeWidth =
          (maxRadius - imageRadius) / 3 * 0.7; // spacing
      final double startRadius = imageRadius + (maxRadius - imageRadius) * 0.15;

      for (int i = 0; i < 3; i++) {
        if (i >= ringValues.length) break;

        final double value = ringValues[i].clamp(0.0, 1.0);
        final double radius = startRadius + i * (ringStrokeWidth * 1.5);

        final Paint ringFgPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringStrokeWidth
          ..color = ringColors[i]
          ..strokeCap = StrokeCap.round;

        // Draw foreground arc
        // Start: -pi/2
        // Sweep: -2 * pi * value (Counter Clockwise)
        const double startAngle = -math.pi / 2;
        final double sweepAngle = -2 * math.pi * value;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          ringFgPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MusclePainter oldDelegate) {
    return true; // Simplified
  }
}
