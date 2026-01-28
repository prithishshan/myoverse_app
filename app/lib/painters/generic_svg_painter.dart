import 'package:flutter/material.dart';
import 'package:app/models/muscle_part.dart';

class GenericSvgPainter extends CustomPainter {
  final List<MusclePart> parts;
  final List<String> highlightedPartIds;

  GenericSvgPainter({required this.parts, List<String>? highlightedPartIds})
    : highlightedPartIds = highlightedPartIds ?? const [];

  @override
  void paint(Canvas canvas, Size size) {
    // We assume the paths are already scaled/positioned correctly relative to each other.
    // However, SVG paths often have their own coordinate system.
    // For now, we draw them as-is. Better scaling/fitting might be needed later.

    // Calculate bounds of strict union of all paths to fit them in the view if needed.
    // But typically SVGs are designed with a viewBox.
    // Since we are parsing raw paths, they will draw in their original coordinate space.
    // It is up to the parent widget (InteractiveSvgViewer) to apply scaling.

    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (var part in parts) {
      final Rect bounds = part.path.getBounds();

      if (highlightedPartIds.contains(part.id)) {
        // Highlighted Gradient (Bright Orange/Yellow)
        paint.shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            const Color(0xFFFFE0B2), // Lighter center
            Colors.orange, // Base color
          ],
          stops: const [0.3, 1.0],
        ).createShader(bounds);
      } else {
        // Unselected Gradient (Dark Gray to Black)
        if (part.id.contains("outline")) {
          // Keep outline simply stroked
          paint.shader = null;
          paint.style = PaintingStyle.stroke;
          paint.color = Colors.white; // White outline
          paint.strokeWidth = 2.0;
        } else {
          paint.style = PaintingStyle.fill;
          Color baseColor = part.defaultColor ?? Colors.grey[800]!;

          paint.shader = RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              baseColor.withOpacity(0.8), // Slightly lighter top-left
              baseColor, // Base color
              Colors.grey[900]!, // Darker shadow (Gray instead of Black)
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(bounds);
        }
      }

      canvas.drawPath(part.path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GenericSvgPainter oldDelegate) {
    return oldDelegate.getAllPartsHash() != getAllPartsHash() ||
        oldDelegate.highlightedPartIds != highlightedPartIds;
  }

  int getAllPartsHash() {
    return Object.hashAll(parts);
  }
}
