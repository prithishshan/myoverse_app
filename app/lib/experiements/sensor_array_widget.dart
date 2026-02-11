import 'dart:async';
import 'package:flutter/material.dart';

class SensorArrayWidget extends StatefulWidget {
  const SensorArrayWidget({super.key, required this.streams});

  /// List of 6 raw streams.
  /// Order:
  /// 0: Anterior Upper
  /// 1: Anterior Lower
  /// 2: Lateral Upper
  /// 3: Lateral Lower
  /// 4: Posterior Upper
  /// 5: Posterior Lower
  final List<Stream<double>> streams;

  @override
  State<SensorArrayWidget> createState() => _SensorArrayWidgetState();
}

class _SensorArrayWidgetState extends State<SensorArrayWidget> {
  // Store current values for the 6 sensors
  final List<double> _values = List.filled(6, 0.0);
  final List<StreamSubscription> _subs = [];
  Timer? _throttleTimer;

  @override
  void initState() {
    super.initState();
    _subscribe();

    // Manual Throttling: Repaint only every 200ms (~5 FPS)
    _throttleTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update CustomPaint
        });
      }
    });
  }

  void _subscribe() {
    for (int i = 0; i < widget.streams.length; i++) {
      if (i < 6) {
        _subs.add(
          widget.streams[i].listen((val) {
            // Update value strictly. DO NOT setState here.
            _values[i] = val.clamp(0.0, 1.0);
          }),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant SensorArrayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streams != oldWidget.streams) {
      for (var sub in _subs) sub.cancel();
      _subs.clear();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    for (var sub in _subs) sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // 2 rows * ~60 height
      width: 200, // 3 cols * ~60 width + spacing
      child: CustomPaint(painter: SensorArrayPainter(values: _values)),
    );
  }
}

class SensorArrayPainter extends CustomPainter {
  SensorArrayPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    // Grid Configuration
    // 3 Columns (Ant, Lat, Post), 2 Rows (Upper, Lower)
    const int cols = 3;
    const int rows = 2;

    // Spacing
    final double spacing = 8.0;

    // Calculate cell size based on available space
    final double totalHSpacing = spacing * (cols - 1);
    final double totalVSpacing = spacing * (rows - 1);

    final double cellWidth = (size.width - totalHSpacing) / cols;
    final double cellHeight = (size.height - totalVSpacing) / rows;

    // Indices mapping:
    // Upper Row (Row 0): [0, 2, 4] -> Ant Up, Lat Up, Post Up
    // Lower Row (Row 1): [1, 3, 5] -> Ant Low, Lat Low, Post Low

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        // Map grid position to sensor index
        // Col 0: 0, 1
        // Col 1: 2, 3
        // Col 2: 4, 5
        // Index = col * 2 + row
        final int sensorIndex = col * 2 + row;

        if (sensorIndex >= values.length) continue;

        final double value = values[sensorIndex];

        // Calculate Position
        final double dx = col * (cellWidth + spacing);
        final double dy = row * (cellHeight + spacing);
        final Rect rect = Rect.fromLTWH(dx, dy, cellWidth, cellHeight);

        // Calculate Color (Yellow -> Orange -> Red)
        Color color;
        if (value < 0.5) {
          final t = value * 2;
          color = Color.lerp(Colors.yellow, Colors.orange, t)!;
        } else {
          final t = (value - 0.5) * 2;
          color = Color.lerp(Colors.orange, Colors.red, t)!;
        }

        final Color baseColor = color;
        final Paint paint = Paint()
          ..color = baseColor
              .withAlpha(
                (255 * (0.9 * value + 0.1)).toInt(),
              ) // Minimum slight visibility
          ..style = PaintingStyle.fill;

        final Paint borderPaint = Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        final RRect rrect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(8),
        );

        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(rrect, borderPaint);

        // Draw Text
        final String textValue = "${(value * 10).toStringAsFixed(1)} mV";
        final TextSpan textSpan = TextSpan(
          text: textValue,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );

        final TextPainter textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(minWidth: 0, maxWidth: cellWidth);

        // Center the text
        final double textX = dx + (cellWidth - textPainter.width) / 2;
        final double textY = dy + (cellHeight - textPainter.height) / 2;

        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SensorArrayPainter oldDelegate) {
    // Always repaint when new values are passed (triggered by Timer -> setState)
    return true;
  }
}
