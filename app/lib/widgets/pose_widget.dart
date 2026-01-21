import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vm;
import '../models/model_3d.dart';
import '../parsers/obj_parser.dart';
import '../painters/model_painter.dart';

class PoseWidget extends StatefulWidget {
  final String modelPath;
  // Keeping elapsedSeconds for backward compatibility if needed, but it won't be used
  final double elapsedSeconds;

  const PoseWidget({
    super.key, 
    this.modelPath = 'assets/body_model/wrist.obj',
    this.elapsedSeconds = 0,
  });

  @override
  State<PoseWidget> createState() => _PoseWidgetState();
}

class _PoseWidgetState extends State<PoseWidget> {
  Model3D? _model;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final objString = await rootBundle.loadString(widget.modelPath);
      final model = OBJParser.parse(objString);
      if (mounted) {
        setState(() {
          _model = model;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
         setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      print('Error loading model: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_model == null) return const Center(child: Text('Failed to load model'));

    final rotationMatrix = vm.Matrix4.identity()
      ..rotateX(_rotationX)
      ..rotateY(_rotationY);

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX += details.delta.dy * 0.01;
              });
            },
            child: CustomPaint(
              painter: ModelPainter(model: _model!, rotationMatrix: rotationMatrix),
              child: Container(),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Drag to rotate', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}