import 'package:vector_math/vector_math.dart';
import '../models/model_3d.dart';

class OBJParser {
  static Model3D parse(String objContent) {
    List<Vector3> vertices = [];
    List<Face> faces = [];
    
    for (var line in objContent.split('\n')) {
      line = line.trim();
      
      if (line.startsWith('v ')) {
        var parts = line.split(RegExp(r'\s+'));
        vertices.add(Vector3(
          double.parse(parts[1]),
          double.parse(parts[2]),
          double.parse(parts[3]),
        ));
      } else if (line.startsWith('f ')) {
        var parts = line.split(RegExp(r'\s+'));
        var v0 = int.parse(parts[1].split('/')[0]) - 1;
        var v1 = int.parse(parts[2].split('/')[0]) - 1;
        var v2 = int.parse(parts[3].split('/')[0]) - 1;
        faces.add(Face(v0, v1, v2));
      }
    }
    
    return Model3D(vertices: vertices, faces: faces);
  }
}
