import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vm;
import '../models/model_3d.dart';

class ModelPainter extends CustomPainter {
  final Model3D model;
  final vm.Matrix4 rotationMatrix;
  
  ModelPainter({required this.model, required this.rotationMatrix});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey[300]!;
    
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 0.5;
    
    // Transform and project vertices
    final transformedVertices = model.vertices.map((v) {
      return rotationMatrix.transform3(v);
    }).toList();
    
    final projected = transformedVertices.map((v) {
      return _project(v, size);
    }).toList();
    
    // Sort faces by depth
    final sortedFaces = model.faces.toList()
      ..sort((a, b) {
        final depthA = (transformedVertices[a.v0].z + transformedVertices[a.v1].z + transformedVertices[a.v2].z) / 3;
        final depthB = (transformedVertices[b.v0].z + transformedVertices[b.v1].z + transformedVertices[b.v2].z) / 3;
        return depthA.compareTo(depthB);
      });
    
    // Draw faces
    for (var face in sortedFaces) {
      final path = Path();
      try {
          path.moveTo(projected[face.v0].dx, projected[face.v0].dy);
          path.lineTo(projected[face.v1].dx, projected[face.v1].dy);
          path.lineTo(projected[face.v2].dx, projected[face.v2].dy);
          path.close();
          
          canvas.drawPath(path, paint);
          canvas.drawPath(path, strokePaint);
      } catch (e) {
          // Skip if indices are out of bounds or projection failed
      }
    }
  }
  
  Offset _project(vm.Vector3 v, Size size) {
    final fov = 500.0;
    final z = v.z + 5.0;
    // Prevent division by zero or negative z if camera is too close
    final safeZ = z < 0.1 ? 0.1 : z; 
    return Offset(
      (v.x * fov / safeZ) + size.width / 2,
      (-v.y * fov / safeZ) + size.height / 2,
    );
  }

  @override
  bool shouldRepaint(ModelPainter old) => true;
}
