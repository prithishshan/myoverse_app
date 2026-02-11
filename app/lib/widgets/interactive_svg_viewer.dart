import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/utils/svg_parser.dart';
import 'package:app/models/muscle_part.dart';
import 'package:get/get.dart';
import 'package:app/controllers/bluetooth_controller.dart';

class GenericSvgPainter extends CustomPainter {
  final List<MuscleGroup> groups;
  // final List<String> highlightedPartIds;

  GenericSvgPainter({required this.groups});
    // : highlightedPartIds = highlightedPartIds ?? const [];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (var group in groups) {
      for (var part in group.parts) {
        final Rect bounds = part.path.getBounds();

        if (group.highlighted) {
          // Highlighted: Subtle elevated glass - Apple style
          paint.shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.5), // Brighter but still subtle
              Colors.white.withValues(alpha: 0.25),
            ],
          ).createShader(bounds);
        } else {
          // Unselected: Glass-like gradient matching the nav bar
          if (part.id.contains("outline")) {
            paint.shader = null;
            paint.style = PaintingStyle.stroke;
            paint.color = Colors.white;
            paint.strokeWidth = 1.0;
          } else {
            paint.style = PaintingStyle.fill;

            // Glass-like gradient matching the floating nav bar
            paint.shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12), // Matches nav glass
                Colors.white.withValues(alpha: 0.06), // Fades out
              ],
            ).createShader(bounds);
          }
        }

        canvas.drawPath(part.path, paint);
      }
    }

    // for (var part in parts) {
    //   final Rect bounds = part.path.getBounds();

    //   if (highlightedPartIds.contains(part.id)) {
    //     // Highlighted: Subtle elevated glass - Apple style
    //     paint.shader = LinearGradient(
    //       begin: Alignment.topLeft,
    //       end: Alignment.bottomRight,
    //       colors: [
    //         Colors.white.withValues(alpha: 0.5), // Brighter but still subtle
    //         Colors.white.withValues(alpha: 0.25),
    //       ],
    //     ).createShader(bounds);
    //   } else {
    //     // Unselected: Glass-like gradient matching the nav bar
    //     if (part.id.contains("outline")) {
    //       paint.shader = null;
    //       paint.style = PaintingStyle.stroke;
    //       paint.color = Colors.white;
    //       paint.strokeWidth = 1.0;
    //     } else {
    //       paint.style = PaintingStyle.fill;

    //       // Glass-like gradient matching the floating nav bar
    //       paint.shader = LinearGradient(
    //         begin: Alignment.topLeft,
    //         end: Alignment.bottomRight,
    //         colors: [
    //           Colors.white.withValues(alpha: 0.12), // Matches nav glass
    //           Colors.white.withValues(alpha: 0.06), // Fades out
    //         ],
    //       ).createShader(bounds);
    //     }
    //   }

    //   canvas.drawPath(part.path, paint);
    // }

    // Draw subtle borders on unselected muscles for glass effect
    // final borderPaint = Paint()
    //   ..style = PaintingStyle.stroke
    //   ..color = Colors.white
    //       .withValues(alpha: 0.15) // Matches nav border
    //   ..strokeWidth = 0.5;

    // for (var part in parts) {
    //   if (!part.id.contains("outline") &&
    //       !highlightedPartIds.contains(part.id)) {
    //     canvas.drawPath(part.path, borderPaint);
    //   }
    // }
  }

  @override
  bool shouldRepaint(covariant GenericSvgPainter oldDelegate) {
    // return oldDelegate.getAllPartsHash() != getAllPartsHash() ||
    for (int i = 0; i < groups.length; i++) {
      if (groups[i].highlighted != oldDelegate.groups[i].highlighted) {
        return true;
      }
    }
    return false;
    // return oldDelegate.groups.map() != oldDelegate.groups;
  }

  // int getAllPartsHash() {
  //   return Object.hashAll(groups);
  // }
}

/// Controller for managing InteractiveSvgViewer state with GetX
class SvgViewerController extends GetxController {
  final SvgParser _parser = SvgParser();

  // Observable state
  final Rxn<ParsedSvgData> data = Rxn<ParsedSvgData>();
  final RxnString loadingError = RxnString();
  final RxBool isLoading = true.obs;
  final RxList<String> localHighlightedIds = <String>[].obs;

  String? _currentAssetPath;

  /// Load SVG from asset path
  Future<void> loadSvg(String assetPath) async {
    // Skip if already loaded same asset
    if (_currentAssetPath == assetPath && data.value != null) {
      return;
    }

    _currentAssetPath = assetPath;
    isLoading.value = true;
    loadingError.value = null;

    try {
      final parsedData = await _parser.parseFromAsset(assetPath);
      data.value = parsedData;
      isLoading.value = false;
    } catch (e) {
      loadingError.value = e.toString();
      isLoading.value = false;
    }
  }

  /// Handle tap on SVG and return the group ID if found
  MuscleGroup? handleTap(Offset touchPoint) {
    if (data.value == null || data.value!.parts.isEmpty) return null;

    // Check if we're in device placement mode
    final bleController = Get.find<BluetoothController>();
    if (!bleController.isPlacingDevice.value) {
      return null;
    }

    // String? tappedId;

    // Hit test: iterate in reverse paint order
    for (var x = data.value!.groups.length - 1; x >= 0; x--) {
      for (var i = data.value!.groups[x].parts.length - 1; i >= 0; i--) {
        if (data.value!.groups[x].parts[i].path.contains(touchPoint)) {
          data.value!.groups[x].highlighted = true;
          return data.value!.groups[x];

          // break;
        }
      }
      // if (tappedId != null) break;
    }
    // for (var i = data.value!.parts.length - 1; i >= 0; i--) {
    //   if (data.value!.parts[i].path.contains(touchPoint)) {
    //     tappedId = data.value!.parts[i].id;
    //     break;
    //   }
    // }

    // if (tappedId != null) {
    //   // Find the group this part belongs to
    //   String groupId = tappedId;
    //   List<String> groupPartIds = [tappedId];

    //   try {
    //     final group = data.value!.groups.firstWhere(
    //       (g) => g.parts.any((p) => p.id == tappedId),
    //     );
    //     groupId = group.id;
    //     groupPartIds = group.parts.map((p) => p.id).toList();
    //   } catch (e) {
    //     debugPrint("No group found for $tappedId");
    //   }
    //   if (bleController.pendingDeviceForAssignment.value != null) {
    //     localHighlightedIds.remove(bleController.pendingDeviceForAssignment.value!.muscleId);
    //   }
    //   localHighlightedIds.value += groupPartIds;
    //   localHighlightedIds.refresh();
    //   return groupId;
    // }

    return null;
  }

  /// Clear local highlights
  // void clearLocalHighlights() {
  //   localHighlightedIds.clear();
  // }
}

class InteractiveSvgViewer extends StatelessWidget {
  final String assetPath;
  final String? outlineAssetPath;
  final Color outlineColor;
  final Function(MuscleGroup group)? onPartTap;
  // final List<String> highlightedMuscleIds;

  const InteractiveSvgViewer({
    Key? key,
    required this.assetPath,
    this.outlineAssetPath,
    this.outlineColor = Colors.white,
    this.onPartTap,
    // this.highlightedMuscleIds = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a unique tag based on asset path for multiple viewers
    final tag = assetPath.hashCode.toString();

    // Initialize controller if not exists
    final svg_controller = Get.put(SvgViewerController(), tag: tag);

    // Load SVG on first build
    svg_controller.loadSvg(assetPath);

    return Obx(() {
      if (svg_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (svg_controller.loadingError.value != null) {
        return Center(
          child: Text('Error loading SVG: ${svg_controller.loadingError.value}'),
        );
      }

      final data = svg_controller.data.value;
      if (data == null || data.parts.isEmpty) {
        return const Center(child: Text('No Muscle data found.'));
      }

      Size canvasSize = data.size;

      // Combine external and local highlights
      // final allHighlights = <String>{
      //   ...controller.localHighlightedIds,
      //   ...highlightedMuscleIds,
      // }.toList();

      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            children: [
              // Bottom Layer: Static Outline
              if (outlineAssetPath != null)
                Positioned.fill(
                  child: SvgPicture.asset(
                    outlineAssetPath!,
                    fit: BoxFit.fill,
                    width: canvasSize.width,
                    height: canvasSize.height,
                    colorFilter: ColorFilter.mode(
                      outlineColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

              // Top Layer: Interactive Muscles
              GestureDetector(
                onTapUp: (details) {
                  final group = svg_controller.handleTap(details.localPosition);
                  if (group != null) {
                    onPartTap?.call(group);
                  }
      //             print(<String>{
      //   ...controller.localHighlightedIds,
      //   ...highlightedMuscleIds,
      // }.toList());
                },
                child: CustomPaint(
                  size: canvasSize,
                  painter: GenericSvgPainter(
                    groups: data.groups,
      //               highlightedPartIds: <String>{
      //   ...controller.localHighlightedIds,
      //   ...highlightedMuscleIds,
      // }.toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
