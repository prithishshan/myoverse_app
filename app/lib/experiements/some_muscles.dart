import 'package:flutter/material.dart';

class MyPainter extends CustomPainter {
  final double scale;

  MyPainter({this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();
    canvas.save();
    // Scaling to fit the drawing within the viewport based on user input.
    canvas.scale(scale, scale);

    // Path number 1

    paint.color = Color.fromARGB(255, 212, 85, 25);
    path = Path();
    path.lineTo(size.width * 2.53, size.height * 2.33);
    path.cubicTo(
      size.width * 2.55,
      size.height * 2.35,
      size.width * 2.57,
      size.height * 2.36,
      size.width * 2.59,
      size.height * 2.38,
    );
    path.cubicTo(
      size.width * 2.56,
      size.height * 2.41,
      size.width * 2.23,
      size.height * 2.73,
      size.width * 2.15,
      size.height * 2.89,
    );
    path.cubicTo(
      size.width * 2.12,
      size.height * 2.94,
      size.width * 2.09,
      size.height * 3.01,
      size.width * 2.07,
      size.height * 3.07,
    );
    path.cubicTo(
      size.width * 2.04,
      size.height * 3.14,
      size.width * 2.01,
      size.height * 3.21,
      size.width * 1.98,
      size.height * 3.26,
    );
    path.cubicTo(
      size.width * 1.94,
      size.height * 3.32,
      size.width * 1.92,
      size.height * 3.33,
      size.width * 1.91,
      size.height * 3.33,
    );
    path.cubicTo(
      size.width * 1.79,
      size.height * 3.3,
      size.width * 1.71,
      size.height * 3.23,
      size.width * 1.67,
      size.height * 3.17,
    );
    path.cubicTo(
      size.width * 1.67,
      size.height * 3.17,
      size.width * 1.67,
      size.height * 3.17,
      size.width * 1.67,
      size.height * 3.17,
    );
    path.cubicTo(
      size.width * 1.66,
      size.height * 3.16,
      size.width * 1.66,
      size.height * 3.15,
      size.width * 1.66,
      size.height * 3.15,
    );
    path.cubicTo(
      size.width * 1.66,
      size.height * 3.15,
      size.width * 1.65,
      size.height * 3.15,
      size.width * 1.65,
      size.height * 3.15,
    );
    path.cubicTo(
      size.width * 1.61,
      size.height * 3.09,
      size.width * 1.6,
      size.height * 3.03,
      size.width * 1.59,
      size.height * 3.02,
    );
    path.cubicTo(
      size.width * 1.59,
      size.height * 3.02,
      size.width * 1.59,
      size.height * 3.02,
      size.width * 1.59,
      size.height * 3.02,
    );
    path.cubicTo(
      size.width * 1.6,
      size.height * 3.01,
      size.width * 1.62,
      size.height * 3,
      size.width * 1.63,
      size.height * 2.99,
    );
    path.cubicTo(
      size.width * 1.65,
      size.height * 2.97,
      size.width * 1.69,
      size.height * 2.92,
      size.width * 1.73,
      size.height * 2.86,
    );
    path.cubicTo(
      size.width * 1.75,
      size.height * 2.82,
      size.width * 1.78,
      size.height * 2.78,
      size.width * 1.8,
      size.height * 2.74,
    );
    path.cubicTo(
      size.width * 1.85,
      size.height * 2.68,
      size.width * 1.91,
      size.height * 2.6,
      size.width * 1.97,
      size.height * 2.54,
    );
    path.cubicTo(
      size.width * 2.12,
      size.height * 2.4,
      size.width * 2.47,
      size.height * 2.34,
      size.width * 2.53,
      size.height * 2.33,
    );
    path.cubicTo(
      size.width * 2.53,
      size.height * 2.33,
      size.width * 2.53,
      size.height * 2.33,
      size.width * 2.53,
      size.height * 2.33,
    );
    path.cubicTo(
      size.width * 2.53,
      size.height * 2.33,
      size.width * 2.53,
      size.height * 2.33,
      size.width * 2.53,
      size.height * 2.33,
    );
    path.cubicTo(
      size.width * 2.53,
      size.height * 2.33,
      size.width * 2.53,
      size.height * 2.33,
      size.width * 2.53,
      size.height * 2.33,
    );
    canvas.drawPath(path, paint);

    // Path number 2

    paint.color = Color.fromARGB(255, 212, 85, 25);
    path = Path();
    path.lineTo(size.width * 2.6, size.height * 2.4);
    path.cubicTo(
      size.width * 2.6,
      size.height * 2.48,
      size.width * 2.6,
      size.height * 2.56,
      size.width * 2.6,
      size.height * 2.64,
    );
    path.cubicTo(
      size.width * 2.6,
      size.height * 2.69,
      size.width * 2.6,
      size.height * 2.74,
      size.width * 2.57,
      size.height * 2.78,
    );
    path.cubicTo(
      size.width * 2.56,
      size.height * 2.79,
      size.width * 2.55,
      size.height * 2.79,
      size.width * 2.55,
      size.height * 2.8,
    );
    path.cubicTo(
      size.width * 2.54,
      size.height * 2.84,
      size.width * 2.51,
      size.height * 2.96,
      size.width * 2.45,
      size.height * 3.05,
    );
    path.cubicTo(
      size.width * 2.43,
      size.height * 3.08,
      size.width * 2.41,
      size.height * 3.11,
      size.width * 2.39,
      size.height * 3.15,
    );
    path.cubicTo(
      size.width * 2.39,
      size.height * 3.15,
      size.width * 2.38,
      size.height * 3.15,
      size.width * 2.38,
      size.height * 3.15,
    );
    path.cubicTo(
      size.width * 2.38,
      size.height * 3.16,
      size.width * 2.38,
      size.height * 3.16,
      size.width * 2.37,
      size.height * 3.17,
    );
    path.cubicTo(
      size.width * 2.33,
      size.height * 3.21,
      size.width * 2.21,
      size.height * 3.31,
      size.width * 2.06,
      size.height * 3.33,
    );
    path.cubicTo(
      size.width * 2.02,
      size.height * 3.34,
      size.width * 1.98,
      size.height * 3.34,
      size.width * 1.94,
      size.height * 3.34,
    );
    path.cubicTo(
      size.width * 2,
      size.height * 3.31,
      size.width * 2.04,
      size.height * 3.22,
      size.width * 2.1,
      size.height * 3.07,
    );
    path.cubicTo(
      size.width * 2.12,
      size.height * 3.01,
      size.width * 2.15,
      size.height * 2.95,
      size.width * 2.18,
      size.height * 2.89,
    );
    path.cubicTo(
      size.width * 2.26,
      size.height * 2.75,
      size.width * 2.53,
      size.height * 2.48,
      size.width * 2.6,
      size.height * 2.4,
    );
    path.cubicTo(
      size.width * 2.6,
      size.height * 2.4,
      size.width * 2.6,
      size.height * 2.4,
      size.width * 2.6,
      size.height * 2.4,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
