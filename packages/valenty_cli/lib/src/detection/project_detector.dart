import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/project_info.dart';

class ProjectDetector {
  Future<ProjectInfo> detect(String path) async {
    final pubspecFile = File(p.join(path, 'pubspec.yaml'));

    if (!pubspecFile.existsSync()) {
      throw FileSystemException(
        'pubspec.yaml not found',
        path,
      );
    }

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap;

    final name = yaml['name'] as String? ?? 'unknown';

    final dependencies = <String>[];
    if (yaml['dependencies'] is YamlMap) {
      dependencies
          .addAll((yaml['dependencies'] as YamlMap).keys.cast<String>());
    }

    final devDependencies = <String>[];
    if (yaml['dev_dependencies'] is YamlMap) {
      devDependencies
          .addAll((yaml['dev_dependencies'] as YamlMap).keys.cast<String>());
    }

    final hasFlutter = dependencies.contains('flutter');
    final hasMainDart = File(p.join(path, 'lib', 'main.dart')).existsSync();

    String? dartSdkConstraint;
    if (yaml['environment'] is YamlMap) {
      dartSdkConstraint = (yaml['environment'] as YamlMap)['sdk'] as String?;
    }

    final flutterSection = yaml['flutter'];
    final hasPlugin =
        flutterSection is YamlMap && flutterSection.containsKey('plugin');

    final ProjectType type;
    if (hasFlutter && hasPlugin) {
      type = ProjectType.flutterPlugin;
    } else if (hasFlutter && hasMainDart) {
      type = ProjectType.flutterApp;
    } else if (hasFlutter) {
      type = ProjectType.flutterPackage;
    } else {
      type = ProjectType.dartPackage;
    }

    return ProjectInfo(
      name: name,
      type: type,
      path: path,
      dependencies: dependencies,
      devDependencies: devDependencies,
      hasFlutter: hasFlutter,
      dartSdkConstraint: dartSdkConstraint,
    );
  }
}
