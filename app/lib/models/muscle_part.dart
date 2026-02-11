import 'package:flutter/painting.dart';
import 'package:get/get.dart';

class MusclePart {
  final String id;
  final Path path;
  late String name;
  final Color? defaultColor;

  MusclePart({required this.id, required this.path, this.defaultColor});
}

class MuscleGroup {
  final String id;
  final List<MusclePart> parts;
  bool highlighted = false;
  late String name;
  MuscleGroup({required this.id, required this.parts}) {
    name = id
    .split('_')
    .where((e) => e.isNotEmpty)
    .map((e) => e[0].toUpperCase() + e.substring(1))
    .join(' ');
    name = name.trim();
  }
}
