import 'package:flutter/painting.dart';

class MusclePart {
  final String id;
  final Path path;
  final Color? defaultColor;

  MusclePart({required this.id, required this.path, this.defaultColor});
}

class MuscleGroup {
  final String id;
  final List<MusclePart> parts;

  MuscleGroup({required this.id, required this.parts});
}
