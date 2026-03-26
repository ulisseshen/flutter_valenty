import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'valenty_config_model.dart';

class ValentyConfig {
  static const String fileName = '.valenty.yaml';

  Future<ValentyConfigModel> load([String? path]) async {
    final filePath = p.join(path ?? Directory.current.path, fileName);
    final file = File(filePath);

    if (!file.existsSync()) {
      throw FileSystemException(
        'Configuration file not found',
        filePath,
      );
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap;
    return ValentyConfigModel.fromYaml(yaml);
  }

  Future<void> save(ValentyConfigModel config, [String? path]) async {
    final filePath = p.join(path ?? Directory.current.path, fileName);
    final file = File(filePath);
    await file.writeAsString(config.toYaml());
  }

  bool exists([String? path]) {
    final filePath = p.join(path ?? Directory.current.path, fileName);
    return File(filePath).existsSync();
  }
}
