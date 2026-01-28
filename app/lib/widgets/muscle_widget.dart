import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/utils/svg_parser.dart'; // [NEW]

class MuscleWidget extends StatefulWidget {
  const MuscleWidget({
    super.key,
    required this.streams,
    this.avgStreams = const [],
    this.imageAsset = 'assets/body_model/shoulder.png',
    this.svgAsset, // [NEW]
    this.muscleId, // [NEW]
    this.showRings = true,
  });

  /// 6 separate streams of intensities (0.0 .. 1.0) for heatmap
  final List<Stream<double>> streams;

  /// 3 averaged streams (0.0 .. 1.0) for activity rings
  final List<Stream<double>> avgStreams;

  /// Asset path for the muscle image
  /// Asset path for the muscle image (Fallback or if svgAsset null)
  final String imageAsset;

  /// Optional: Path to the SVG file containing the muscle part
  final String? svgAsset;

  /// Optional: ID of the muscle part within the SVG
  final String? muscleId;

  /// Whether to show the activity rings
  final bool showRings;

  @override
  State<MuscleWidget> createState() => _MuscleWidgetState();
}

class _MuscleWidgetState extends State<MuscleWidget>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  bool _imageLoaded = false;

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

  // 10s Rolling Average History (timestamp, value)
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
    _loadContent(); // wrapper for image or svg
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

  Future<void> _loadContent() async {
    if (widget.svgAsset != null && widget.muscleId != null) {
      // Load SVG Path
      await _loadSvgPath();
    } else {
      // Load PNG Image
      await _loadImage();
    }
  }

  Future<void> _loadSvgPath() async {
    try {
      final parser = SvgParser();
      final data = await parser.parseFromAsset(widget.svgAsset!);

      // Try to find a group matching the muscleId
      Path? combinedPath;

      try {
        // Try finding a group first
        final group = data.groups.firstWhere((g) => g.id == widget.muscleId);
        combinedPath = Path();
        for (var part in group.parts) {
          combinedPath.addPath(part.path, Offset.zero);
        }
      } catch (_) {
        // Fallback: Try to find a single part
        try {
          final part = data.parts.firstWhere((p) => p.id == widget.muscleId);
          combinedPath = part.path;
        } catch (e) {
          debugPrint(
            "MuscleWidget: Muscle ID ${widget.muscleId} not found in SVG.",
          );
        }
      }

      if (combinedPath != null) {
        if (mounted) {
          setState(() {
            _musclePath = combinedPath;
            _svgSize = data.size;
            _svgLoaded = true;
          });
        }
      } else {
        // Fallback to image if no path found
        await _loadImage();
      }
    } catch (e) {
      debugPrint("Error loading SVG asset: $e");
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
    // We store it in _avgCurrents[0]
    double sum = 0;
    for (var val in _currents) {
      sum += val;
    }
    final double globalAvg = sum / 6.0;

    // Smooth the global average for the ring
    // We use _avgCurrents[0] as current ring value, _avgTargets[0] as target (globalAvg)

    // Actually simpler: just smoothing the average of currents IS enough?
    // Or should we average the TARGETS and smooth that?
    // Let's use the average of the smoothed currents as the ring value directly.
    // It's already smoothed.

    if ((_avgCurrents[0] - globalAvg).abs() > 0.001) {
      _avgCurrents[0] = globalAvg;
      needsRepaint = true;
    }

    // === Rolling Average (10s) ===
    // Add current global average to history
    _history.add((now, globalAvg));

    // Prune old history (> 10s)
    // 10,000 ms
    _history.removeWhere((item) => now - item.$1 > 5000);

    // Calculate new rolling average
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

    // Reps Logic:
    // Increment if current average crosses 0.5 threshold from below
    // Use smoothed value _avgCurrents[0] for stability
    if (_lastAvg < 0.4 && _avgCurrents[0] >= 0.4) {
      _reps++;
      needsRepaint = true; // Force rebuild
      // HapticFeedback.mediumImpact(); // Optional
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
        oldWidget.muscleId != widget.muscleId) {
      if (oldWidget.muscleId != widget.muscleId) {
        // Reload content
        _svgLoaded = false;
        _imageLoaded = false;
        _loadContent();
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
    bool ready =
        (_svgLoaded && _musclePath != null) || (_imageLoaded && _image != null);

    if (!ready) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use minimum dimension to ensure circles
        final double size = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none, // Allow children to position outside bounds
          children: [
            CustomPaint(
              painter: MusclePainter(
                image: _image, // nullable now
                musclePath: _musclePath, // nullable
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
              bottom: -40, // Move lower
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
              bottom: -40, // Move lower
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A), // Zinc-900 like
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
    this.image,
    this.musclePath,
    this.svgSize,
    required this.points,
    required this.intensities,
    required this.ringValues,
    required this.showRings,
  });

  final ui.Image? image;
  final Path? musclePath;
  final Size? svgSize;
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

    // Draw Image or SVG Masked
    canvas.save();

    final imageRect = Rect.fromCircle(center: center, radius: imageRadius);
    canvas.clipPath(Path()..addOval(imageRect));

    // Fill background with black
    canvas.drawPaint(Paint()..color = Colors.black);

    // Bounding Box for Heatmap mapping
    Rect contentBoundingBox = imageRect;

    if (musclePath != null && svgSize != null) {
      // === DRAW SVG PATH ===
      // We want to fit the muscle path into the imageRect.
      // 1. Get bounds of the path itself.
      final Rect pathBounds = musclePath!.getBounds();

      // 2. Calculate scale to fit pathBounds into imageRect (contain)
      final double scaleX = imageRect.width / pathBounds.width;
      final double scaleY = imageRect.height / pathBounds.height;
      final double scale =
          math.min(scaleX, scaleY) * 0.9; // 90% fill so it doesn't touch edges

      // 3. Transform Matrix
      // Translate to origin -> Scale -> Translate to center of imageRect
      final double dragX = imageRect.center.dx - pathBounds.center.dx * scale;
      final double dragY = imageRect.center.dy - pathBounds.center.dy * scale;

      canvas.translate(dragX, dragY);
      canvas.scale(scale, scale);

      // Draw the muscle shape
      final Paint musclePaint = Paint()..style = PaintingStyle.fill;

      // Shaded Gradient (Dark Gray to Black) - Matching Home Page style
      final Color baseColor = Colors.grey[800]!;

      final Gradient gradient = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [
          baseColor.withOpacity(0.8),
          baseColor,
          Colors.grey[900]!, // Shading gray instead of black
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      musclePaint.shader = gradient.createShader(pathBounds);

      canvas.drawPath(musclePath!, musclePaint);

      // Draw outline
      // final Paint outlinePaint = Paint()
      //   ..color = Colors
      //       .white // White outline
      //   ..style = PaintingStyle.stroke
      //   ..strokeWidth = 1.0 / scale; // Constant thickness

      // canvas.drawPath(musclePath!, outlinePaint);

      // Restore logic for heatmap:
      // Heatmap points need to map to the drawn muscle area (approximately).
      // Since we transformed the canvas, if we draw heatmap circles now, they will be affected by the transform.
      // This is actually GOOD if we map 0..1 to the path bounds.

      // Let's redefine contentBoundingBox to be the path bounds in current local space
      contentBoundingBox = pathBounds;
    } else if (image != null) {
      // === DRAW PNG IMAGE ===
      final src = Rect.fromLTWH(
        0,
        0,
        image!.width.toDouble(),
        image!.height.toDouble(),
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
      canvas.drawImageRect(image!, inputRect, outputRect, Paint());

      // For PNG, content box is the full output rect (relative to canvas, not transformed)
      contentBoundingBox = outputRect;
    }

    // Draw Heatmaps
    // We need to handle the canvas state carefully.
    // If SVG, we are transformed.
    // Let's draw heatmaps while transformed?
    // If we draw a circle while scaled, the circle is also scaled.
    // If aspect ratio is preserved (uniform scale), it's still a circle.

    for (int i = 0; i < points.length; i++) {
      if (i >= intensities.length) break;

      final double intensity = intensities[i];
      final Offset normPos = points[i];

      final double cx =
          contentBoundingBox.left + normPos.dx * contentBoundingBox.width;
      final double cy =
          contentBoundingBox.top + normPos.dy * contentBoundingBox.height;

      // Color logic
      Color color;
      if (intensity < 0.5) {
        final t = intensity * 2;
        color = Color.lerp(Colors.yellow, Colors.orange, t)!;
      } else {
        final t = (intensity - 0.5) * 2;
        color = Color.lerp(Colors.orange, Colors.red, t)!;
      }

      // Radius
      double radius =
          (imageRect.width / 2) * 0.35; // base relative to overall widget size
      if (musclePath != null) {
        // If we are scaled, we need to adjust radius so it looks consistent?
        // Actually, if mapped to path bounds, maybe we WANT it to scale with the muscle?
        // Let's try keeping it proportional to the bounding box.
        radius = contentBoundingBox.width * 0.25;
      } else {
        radius = imageRadius * 0.35;
      }

      final Paint paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [color.withOpacity(0.9 * intensity), color.withOpacity(0.0)],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    canvas.restore(); // Remove clip and transform

    // 2. Draw Rings
    // Single Symmetric Ring: Starts at bottom (pi/2) and grows both ways.
    // Color: Yellow -> Orange -> Red

    if (showRings && ringValues.isNotEmpty) {
      // We expect ringValues[0] to be the global average
      final double value = ringValues[0].clamp(0.0, 1.0);

      final double ringStrokeWidth = (maxRadius - imageRadius) * 0.3;
      final double ringRadius = imageRadius + (maxRadius - imageRadius) * 0.5;

      // Color logic (Yellow -> Orange -> Red)
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

      // Draw Background Track (Gray)
      final Paint trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStrokeWidth
        ..color =
            Colors.grey[800]! // Or any preferred gray
        ..strokeCap = StrokeCap.round;

      // Draw full track (or partial if we want gaps?)
      // Let's draw full 2*pi for the background based on "gray target intesity track"
      canvas.drawCircle(center, ringRadius, trackPaint);

      // Draw symmetric arc starting from bottom (pi/2)
      // Total sweep if full: 2*pi.
      // If we want it to grow from bottom upwards on both sides:
      // Start Angle = pi/2 - (sweep/2)
      // Sweep Angle = totalSweep * value
      // Let's say max coverage is 300 degrees (leaving a gap at top) or full circle?
      // "around the muscle heatmap" implies likely full or near full.
      // Let's go with full circle capacity (2*pi).

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
    return true; // Simplified to always repaint when new instance is created
  }
}
