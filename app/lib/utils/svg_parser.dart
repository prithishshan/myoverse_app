import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:app/models/muscle_part.dart';

class ParsedSvgData {
  final List<MusclePart> parts;
  final List<MuscleGroup> groups; // [NEW]
  final Size size;

  ParsedSvgData({
    required this.parts,
    required this.groups, // [NEW]
    required this.size,
  });
}

class SvgParser {
  /// Parses an SVG asset and returns [ParsedSvgData] containing parts and canvas size.
  Future<ParsedSvgData> parseFromAsset(String assetPath) async {
    try {
      final String svgContent = await rootBundle.loadString(assetPath);
      final XmlDocument document = XmlDocument.parse(svgContent);
      final List<MusclePart> parts = [];

      // Extract details from the root <svg> element
      // Use rootElement directly as it is more robust than getElement('svg') on the doc
      final XmlElement root = document.rootElement;
      Size size = Size.zero;

      if (root.name.local == 'svg') {
        final String? viewBox = root.getAttribute('viewBox');
        final String? width = root.getAttribute('width');
        final String? height = root.getAttribute('height');

        if (viewBox != null) {
          final List<String> parts = viewBox.split(RegExp(r'[ ,]+'));
          if (parts.length == 4) {
            final double w = double.tryParse(parts[2]) ?? 0;
            final double h = double.tryParse(parts[3]) ?? 0;
            size = Size(w, h);
          }
        }

        // Fallback to width/height attributes if viewBox is missing or invalid
        if (size == Size.zero && width != null && height != null) {
          final double? w = double.tryParse(width.replaceAll('px', ''));
          final double? h = double.tryParse(height.replaceAll('px', ''));
          if (w != null && h != null) {
            size = Size(w, h);
          }
        }
      }

      // Find all 'path' elements in the document
      final Iterable<XmlElement> paths = document.findAllElements('path');

      for (var element in paths) {
        final String? id = element.getAttribute('id');
        final String? d = element.getAttribute('d');

        if (id != null && d != null) {
          // Parse the SVG path data into a Flutter Path
          final Path path = parseSvgPathData(d);
          parts.add(MusclePart(id: id, path: path));
        } else if (d != null) {
          // Debug log for skipped paths (too spammy if many, enabling only if needed or sample)
          // print('SvgParser: Skipping path without ID');
        }
      }

      // Logic to creating groups
      final Map<String, List<MusclePart>> groupedParts = {};

      for (var part in parts) {
        String groupId = part.id;
        final segments = part.id.split('_');

        // If id is side_group_part (3 segments or more), group is side_group
        // Example: right_bicep_long -> right_bicep
        if (segments.length >= 3) {
          groupId = "${segments[0]}_${segments[1]}";
        } else {
          // If id is side_group (2 segments), it is its own group
          // Example: right_pectoral -> right_pectoral
          groupId = part.id; // Or maybe segments[0]_segments[1] if exists
        }

        if (!groupedParts.containsKey(groupId)) {
          groupedParts[groupId] = [];
        }
        groupedParts[groupId]!.add(part);
      }

      final List<MuscleGroup> groups = groupedParts.entries.map((e) {
        return MuscleGroup(id: e.key, parts: e.value);
      }).toList();

      return ParsedSvgData(parts: parts, groups: groups, size: size);
    } catch (e) {
      print('Error parsing SVG asset $assetPath: $e');
      rethrow;
    }
  }
}
