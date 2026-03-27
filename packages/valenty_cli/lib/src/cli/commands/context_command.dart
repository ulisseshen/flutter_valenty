import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../analyzers/builder_introspector.dart';
import '../../analyzers/models/feature_info.dart';
import '../../config/valenty_config.dart';

/// `valenty context` — output the full project state for AI consumption.
///
/// Emits structured YAML (default) or JSON (`--format json`) describing
/// every feature, builder, and method in the project.
class ContextCommand extends Command<void> {
  ContextCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'format',
      abbr: 'f',
      help: 'Output format.',
      allowed: ['yaml', 'json'],
      defaultsTo: 'yaml',
    );
  }

  final Logger _logger;

  @override
  String get name => 'context';

  @override
  String get description =>
      'Output full project state as YAML or JSON for AI consumption.';

  @override
  Future<void> run() async {
    final format = argResults?['format'] as String? ?? 'yaml';
    final projectPath = Directory.current.path;

    final introspector = BuilderIntrospector();
    final features = introspector.inspect(projectPath);

    final configInfo = _loadConfigInfo(projectPath);

    final data = <String, dynamic>{
      'valenty': <String, dynamic>{
        'version': '0.1.0',
        'projectPath': projectPath,
        if (configInfo != null) 'config': configInfo,
        'features': features.map((f) => f.toJson()).toList(),
        'summary': _buildSummary(features),
      },
    };

    if (format == 'json') {
      _logger.info(const JsonEncoder.withIndent('  ').convert(data));
    } else {
      _logger.info(_toYaml(data));
    }
  }

  Map<String, dynamic>? _loadConfigInfo(String projectPath) {
    final config = ValentyConfig();
    if (!config.exists(projectPath)) return null;

    try {
      // Read the raw yaml file synchronously for simplicity.
      final file = File('$projectPath/${ValentyConfig.fileName}');
      final content = file.readAsStringSync();
      // Return a simple marker so the context knows config exists.
      return {
        'file': ValentyConfig.fileName,
        'exists': true,
        'raw': content.trim(),
      };
    } catch (_) {
      return {'file': ValentyConfig.fileName, 'exists': false};
    }
  }

  Map<String, dynamic> _buildSummary(List<FeatureInfo> features) {
    var totalBuilders = 0;
    var totalMethods = 0;
    final phases = <String, int>{};

    for (final feature in features) {
      for (final builder in feature.builders) {
        totalBuilders++;
        totalMethods += builder.methods.length;
        phases[builder.phase] = (phases[builder.phase] ?? 0) + 1;
      }
    }

    return {
      'totalFeatures': features.length,
      'totalBuilders': totalBuilders,
      'totalMethods': totalMethods,
      'buildersByPhase': phases,
    };
  }

  /// Converts a nested [Map] to a YAML-formatted string.
  ///
  /// This is a lightweight serialiser (no external dependency needed beyond
  /// what the CLI already uses). It handles [Map], [List], [String], [num],
  /// [bool], and `null`.
  String _toYaml(dynamic value, {int indent = 0}) {
    final buffer = StringBuffer();
    _writeYaml(buffer, value, indent: indent, isRoot: true);
    return buffer.toString().trimRight();
  }

  void _writeYaml(
    StringBuffer buffer,
    dynamic value, {
    int indent = 0,
    bool isRoot = false,
  }) {
    final prefix = ' ' * indent;

    if (value is Map) {
      if (!isRoot) buffer.writeln();
      for (final entry in value.entries) {
        final key = entry.key;
        final val = entry.value;

        if (val is Map || val is List) {
          buffer.write('$prefix$key:');
          _writeYaml(buffer, val, indent: indent + 2);
        } else {
          buffer.writeln('$prefix$key: ${_scalarToYaml(val)}');
        }
      }
    } else if (value is List) {
      if (value.isEmpty) {
        buffer.writeln(' []');
        return;
      }
      buffer.writeln();
      for (final item in value) {
        if (item is Map) {
          // First key on same line as dash, rest indented.
          final entries = item.entries.toList();
          if (entries.isEmpty) {
            buffer.writeln('$prefix- {}');
            continue;
          }
          final first = entries.first;
          if (first.value is Map || first.value is List) {
            buffer.write('$prefix- ${first.key}:');
            _writeYaml(buffer, first.value, indent: indent + 4);
          } else {
            buffer.writeln(
              '$prefix- ${first.key}: ${_scalarToYaml(first.value)}',
            );
          }
          for (var i = 1; i < entries.length; i++) {
            final e = entries[i];
            if (e.value is Map || e.value is List) {
              buffer.write('$prefix  ${e.key}:');
              _writeYaml(buffer, e.value, indent: indent + 4);
            } else {
              buffer.writeln(
                '$prefix  ${e.key}: ${_scalarToYaml(e.value)}',
              );
            }
          }
        } else {
          buffer.writeln('$prefix- ${_scalarToYaml(item)}');
        }
      }
    } else {
      buffer.writeln(' ${_scalarToYaml(value)}');
    }
  }

  String _scalarToYaml(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is String) {
      if (value.contains('\n')) {
        // Use literal block scalar for multiline strings.
        final indented = value.split('\n').map((line) => '  $line').join('\n');
        return '|\n$indented';
      }
      // Quote strings that could be misinterpreted.
      if (value.isEmpty ||
          value.contains(':') ||
          value.contains('#') ||
          value.contains("'") ||
          value.startsWith('{') ||
          value.startsWith('[') ||
          value == 'true' ||
          value == 'false' ||
          value == 'null') {
        return '"${value.replaceAll('"', r'\"')}"';
      }
      return value;
    }
    return value.toString();
  }
}
