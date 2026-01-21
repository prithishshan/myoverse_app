import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class PoseWidget extends StatefulWidget {
  const PoseWidget({super.key, this.elapsedSeconds = 0});
  final double elapsedSeconds;

  @override
  State<PoseWidget> createState() => _PoseWidgetState();
}

class _PoseWidgetState extends State<PoseWidget> {
  Scene scene = Scene();

  @override
  void initState() {
    final bodyModel = Node.fromAsset('build/models/wrist.model').then((
      modelNode,
    ) {
      scene.add(modelNode);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScenePainter(scene, widget.elapsedSeconds));
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene, this.elapsedTime);
  Scene scene;
  double elapsedTime;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = PerspectiveCamera(
      position: vm.Vector3(sin(elapsedTime) * 5, 2, cos(elapsedTime) * 5),
      target: vm.Vector3(0, 0, 0),
    );

    scene.render(camera, canvas, viewport: Offset.zero & size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}