import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/utils/svg_parser.dart';
import 'package:app/painters/generic_svg_painter.dart';

class InteractiveSvgViewer extends StatefulWidget {
  final String assetPath;
  final String? outlineAssetPath;
  final Color outlineColor;
  final Function(String id)? onPartTap;

  const InteractiveSvgViewer({
    Key? key,
    required this.assetPath,
    this.outlineAssetPath,
    this.outlineColor = const Color(0xFFD17A4A),
    this.onPartTap,
  }) : super(key: key);

  @override
  State<InteractiveSvgViewer> createState() => _InteractiveSvgViewerState();
}

class _InteractiveSvgViewerState extends State<InteractiveSvgViewer> {
  final SvgParser _parser = SvgParser();
  ParsedSvgData? _data;
  String? _loadingError;
  bool _isLoading = true;
  String? _highlightedId;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(InteractiveSvgViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      final data = await _parser.parseFromAsset(widget.assetPath);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadingError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleTap(TapUpDetails details) {
    if (_data == null || _data!.parts.isEmpty) return;

    // We need to transform the local touch point back to the SVG coordinate system
    // The CustomPaint is likely being scaled.
    // For now, let's assume direct mapping or simple scaling if we add it.

    // If we use a FittedBox, the coordinate system of the child (CustomPaint)
    // matches the SVG coordinates (assuming the CustomPaint size is the SVG size).

    // A robust way corresponds to the render object, but let's try a simple hit test loop first.
    // Note: This hit test assumes 1:1 mapping if wrapped in a scroll view or similar,
    // OR we need to inverse the transform if we Scaled it.

    // Let's rely on the RenderBox to get local coordinates, which 'details.localPosition' provides.
    // If we scale the canvas in the painter, we need to inverse scale the point.
    // If we scale the WIDGET (e.g. InteractiveViewer), the local position is already in the child's local coordinates.

    final touchPoint = details.localPosition;

    String? tappedId;

    // Hit test: iterate in reverse paint order
    for (var i = _data!.parts.length - 1; i >= 0; i--) {
      if (_data!.parts[i].path.contains(touchPoint)) {
        tappedId = _data!.parts[i].id;
        break;
      }
    }

    if (tappedId != null) {
      setState(() {
        _highlightedId = tappedId;
      });
      widget.onPartTap?.call(tappedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadingError != null) {
      return Center(child: Text('Error loading SVG: $_loadingError'));
    }

    if (_data == null || _data!.parts.isEmpty) {
      return const Center(child: Text('No skeletal data found.'));
    }

    // Use the parsed SVG viewbox size if available, otherwise fallback to path bounds
    Size canvasSize = _data!.size;
    if (canvasSize == Size.zero) {
      // Fallback: calculate from paths
      Rect totalBounds = _data!.parts.first.path.getBounds();
      for (var p in _data!.parts)
        totalBounds = totalBounds.expandToInclude(p.path.getBounds());
      canvasSize = Size(totalBounds.right, totalBounds.bottom);
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: Stack(
          children: [
            // Bottom Layer: Static Outline
            if (widget.outlineAssetPath != null)
              Positioned.fill(
                child: SvgPicture.asset(
                  widget.outlineAssetPath!,
                  fit: BoxFit
                      .fill, // Ensure it fills the exact viewBox size coordinates
                  width: canvasSize.width,
                  height: canvasSize.height,
                  colorFilter: ColorFilter.mode(
                    widget.outlineColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),

            // Top Layer: Interactive Muscles
            GestureDetector(
              onTapUp: _handleTap,
              child: CustomPaint(
                size: canvasSize,
                painter: GenericSvgPainter(
                  parts: _data!.parts,
                  highlightedPartId: _highlightedId,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
