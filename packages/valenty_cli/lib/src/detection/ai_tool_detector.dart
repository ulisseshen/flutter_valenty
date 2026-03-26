import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/ai_tool_type.dart';

class AiToolDetector {
  List<AiToolType> detect(String path) {
    final detected = <AiToolType>[];

    for (final tool in AiToolType.values) {
      final toolPath = p.join(path, tool.configPath);
      if (tool == AiToolType.codex) {
        if (File(toolPath).existsSync()) {
          detected.add(tool);
        }
      } else {
        if (Directory(toolPath).existsSync()) {
          detected.add(tool);
        }
      }
    }

    return detected;
  }
}
