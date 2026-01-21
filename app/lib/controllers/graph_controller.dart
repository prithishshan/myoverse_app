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
    required this.buffer,
    required this.strokeWidth,
    required this.padding,
    this.lineColor = Colors.white,
    this.fixedMin,
    this.fixedMax,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final RingBuffer buffer;
  final double strokeWidth;
  final EdgeInsets padding;
  final Color lineColor;
  final double? fixedMin;
  final double? fixedMax;

  @override
  void paint(Canvas canvas, Size size) {
    final samples = buffer.getListOldestToNewest();
    final rect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    if (samples.length < 2) return;

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

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = lineColor;

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant LineGraphPainter oldDelegate) {
    return oldDelegate.buffer != buffer ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.padding != padding ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fixedMin != fixedMin ||
        oldDelegate.fixedMax != fixedMax;
  }
}

class SensorLineGraph extends StatefulWidget {
  const SensorLineGraph({
    super.key,
    required this.stream,
    this.hz = 100,
    this.windowSeconds = 5,
    this.repaintFps = 60,
    this.strokeWidth = 2,
    this.padding = const EdgeInsets.all(12),
    this.lineColor = Colors.white,
    this.fixedMin,
    this.fixedMax,
  });

  final Stream<double> stream;

  /// Your sampling rate (100 Hz).
  final int hz;

  /// Rolling time window shown on screen.
  final int windowSeconds;

  /// How often we redraw (30 or 60 recommended).
  final int repaintFps;

  final double strokeWidth;
  final EdgeInsets padding;
  final Color lineColor;
  final double? fixedMin;
  final double? fixedMax;

  @override
  State<SensorLineGraph> createState() => _SensorLineGraphState();
}

class _SensorLineGraphState extends State<SensorLineGraph> {
  late RingBuffer _buf;
  StreamSubscription<double>? _sub;

  // Use a notifier purely to drive painter repaints.
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  Timer? _timer;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _rebuildBuffer();
    _sub = widget.stream.listen((v) {
      _buf.add(v);
      _dirty = true; // mark that we have new data
    });
    _startRepaintTimer();
  }

  void _rebuildBuffer() {
    // final cap = widget.hz * widget.windowSeconds; // e.g., 100*5=500
    _buf = RingBuffer(widget.hz, widget.windowSeconds);
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

    // final needsNewBuffer 
    //     oldWidget.hz != widget.hz ||
    //     oldWidget.windowSeconds != widget.windowSeconds;
    // if (needsNewBuffer) _rebuildBuffer();

    // if (oldWidget.repaintFps != widget.repaintFps) _startRepaintTimer();

    if (oldWidget.stream != widget.stream) {
      _sub?.cancel();
      _sub = widget.stream.listen((v) {
        _buf.add(v);
        _dirty = true;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert once per build; build only occurs at repaintFps due to _frame.
    // final samples = _buf.getListOldestToNewest();

    return RepaintBoundary(
      child: CustomPaint(
        painter: LineGraphPainter(
          buffer: _buf,
          strokeWidth: widget.strokeWidth,
          padding: widget.padding,
          lineColor: widget.lineColor,
          fixedMin: widget.fixedMin,
          fixedMax: widget.fixedMax,
          repaint: _frame,
        ),
        size: Size.infinite,
      ),
    );
  }
}
