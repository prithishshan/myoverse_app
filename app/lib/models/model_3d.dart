import 'package:vector_math/vector_math.dart';

class Model3D {
  final List<Vector3> vertices;
  final List<Face> faces;
  
  Model3D({required this.vertices, required this.faces});
}

class Face {
  final int v0, v1, v2;
  Face(this.v0, this.v1, this.v2);
}
