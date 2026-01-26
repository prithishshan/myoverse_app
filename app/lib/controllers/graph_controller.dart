import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class RingBuffer {
  RingBuffer(int freq, int range)
    : capacity = freq * range,
      _data = List.filled(freq * range, 0.0);

  final int capacity;
  final List<double> _data;
  int _write = 0;
  int _count = 0;

  int getLength() {
    return _count;
  }

  void add(double v) {
    _data[_write] = v;
    _write = (_write + 1) % capacity;
    if (_count < capacity) _count++;
  }

  List<double> getListOldestToNewest() {
    if (_count == 0) return const [];
    final start = (_write - _count) % capacity;
    final out = <double>[];
    for (int i = 0; i < _count; i++) {
      out.add(_data[(start + i) % capacity]);
    }
    return out;
  }
}

class LineGraphPainter extends CustomPainter {
  LineGraphPainter({
    required this.buffers,
    required this.strokeWidth,
    required this.padding,
    required this.lineColors,
    this.fixedMin,
    this.fixedMax,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<RingBuffer> buffers;
  final double strokeWidth;
  final EdgeInsets padding;
  final List<Color> lineColors;
  final double? fixedMin;
  final double? fixedMax;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    for (int j = 0; j < buffers.length; j++) {
      final buffer = buffers[j];
      final samples = buffer.getListOldestToNewest();

      if (samples.length < 2) continue;

      final minV = fixedMin ?? samples.reduce(math.min);
      final maxV = fixedMax ?? samples.reduce(math.max);
      final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

      final path = Path();
      for (int i = 0; i < samples.length; i++) {
        final t = i / (samples.length - 1);
        final x = rect.left + t * rect.width;

        final yNorm = (samples[i] - minV) / range; // 0..1
        final y = rect.bottom - yNorm * rect.height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final color = j < lineColors.length ? lineColors[j] : Colors.white;

      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = color;

      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant LineGraphPainter oldDelegate) {
    return true; // Simple approach, triggers on frame tick anyway
  }
}

class SensorLineGraph extends StatefulWidget {
  const SensorLineGraph({
    super.key,
    required this.streams,
    this.hz = 100,
    this.windowSeconds = 5,
    this.repaintFps = 60,
    this.strokeWidth = 2,
    this.padding = const EdgeInsets.all(12),
    this.lineColors = const [Colors.white],
    this.fixedMin,
    this.fixedMax,
  });

  final List<Stream<double>> streams;

  /// Your sampling rate (100 Hz).
  final int hz;

  /// Rolling time window shown on screen.
  final int windowSeconds;

  /// How often we redraw (30 or 60 recommended).
  final int repaintFps;

  final double strokeWidth;
  final EdgeInsets padding;
  final List<Color> lineColors;
  final double? fixedMin;
  final double? fixedMax;

  @override
  State<SensorLineGraph> createState() => _SensorLineGraphState();
}

class _SensorLineGraphState extends State<SensorLineGraph> {
  late List<RingBuffer> _buffers;
  final List<StreamSubscription<double>> _subs = [];

  // Use a notifier purely to drive painter repaints.
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  Timer? _timer;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _rebuildBuffers();
    _subscribeStreams();
    _startRepaintTimer();
  }

  void _rebuildBuffers() {
    _buffers = List.generate(
      widget.streams.length,
      (_) => RingBuffer(widget.hz, widget.windowSeconds),
    );
  }

  void _subscribeStreams() {
    for (var sub in _subs) {
      sub.cancel();
    }
    _subs.clear();

    for (int i = 0; i < widget.streams.length; i++) {
      _subs.add(
        widget.streams[i].listen((v) {
          if (i < _buffers.length) {
            _buffers[i].add(v);
            _dirty = true;
          }
        }),
      );
    }
  }

  void _startRepaintTimer() {
    _timer?.cancel();
    final intervalMs = (1000 / widget.repaintFps).round(); // ~16ms for 60fps
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_dirty) {
        _dirty = false;
        _frame.value++; // triggers CustomPainter repaint
      }
    });
  }

  @override
  void didUpdateWidget(covariant SensorLineGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.streams != widget.streams) {
      _rebuildBuffers(); // Might need to clear if count changes
      _subscribeStreams();
    }
  }

  @override
  void dispose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    _timer?.cancel();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: LineGraphPainter(
          buffers: _buffers,
          strokeWidth: widget.strokeWidth,
          padding: widget.padding,
          lineColors: widget.lineColors,
          fixedMin: widget.fixedMin,
          fixedMax: widget.fixedMax,
          repaint: _frame,
        ),
        size: Size.infinite,
      ),
    );
  }
}
