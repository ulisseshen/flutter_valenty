import 'package:yaml/yaml.dart';

class ValentyConfigModel {
  const ValentyConfigModel({
    this.version = '0.1.0',
    this.projectName = '',
    this.projectType = 'dart',
    this.pyramidModel = 'modern',
    this.pyramidLevels = const [
      'unit',
      'narrow_integration',
      'broad_integration',
      'contract',
      'component',
      'e2e',
      'acceptance',
      'exploratory',
    ],
    this.fixtureSetupPattern = 'arrange_act_assert',
    this.testDoublesPattern = 'mock',
    this.testOrganization = 'by_feature',
    this.dslOutputDirectory = 'test/',
    this.language = 'en',
    this.aiToolsAutoDetect = true,
    this.aiToolsGenerateFor = const [],
  });

  factory ValentyConfigModel.fromYaml(YamlMap yaml) {
    return ValentyConfigModel(
      version: yaml['version'] as String? ?? '0.1.0',
      projectName: yaml['project_name'] as String? ?? '',
      projectType: yaml['project_type'] as String? ?? 'dart',
      pyramidModel: yaml['pyramid_model'] as String? ?? 'modern',
      pyramidLevels: (yaml['pyramid_levels'] as YamlList?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      fixtureSetupPattern:
          yaml['fixture_setup_pattern'] as String? ?? 'arrange_act_assert',
      testDoublesPattern: yaml['test_doubles_pattern'] as String? ?? 'mock',
      testOrganization: yaml['test_organization'] as String? ?? 'by_feature',
      dslOutputDirectory: yaml['dsl_output_directory'] as String? ?? 'test/',
      language: yaml['language'] as String? ?? 'en',
      aiToolsAutoDetect: yaml['ai_tools_auto_detect'] as bool? ?? true,
      aiToolsGenerateFor: (yaml['ai_tools_generate_for'] as YamlList?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  final String version;
  final String projectName;
  final String projectType;
  final String pyramidModel;
  final List<String> pyramidLevels;
  final String fixtureSetupPattern;
  final String testDoublesPattern;
  final String testOrganization;
  final String dslOutputDirectory;
  final String language;
  final bool aiToolsAutoDetect;
  final List<String> aiToolsGenerateFor;

  String toYaml() {
    final buffer = StringBuffer()
      ..writeln('version: "$version"')
      ..writeln('project_name: "$projectName"')
      ..writeln('project_type: "$projectType"')
      ..writeln('pyramid_model: "$pyramidModel"')
      ..writeln('pyramid_levels:');
    for (final level in pyramidLevels) {
      buffer.writeln('  - $level');
    }
    buffer
      ..writeln('fixture_setup_pattern: "$fixtureSetupPattern"')
      ..writeln('test_doubles_pattern: "$testDoublesPattern"')
      ..writeln('test_organization: "$testOrganization"')
      ..writeln('dsl_output_directory: "$dslOutputDirectory"')
      ..writeln('language: "$language"')
      ..writeln('ai_tools_auto_detect: $aiToolsAutoDetect')
      ..writeln('ai_tools_generate_for:');
    for (final tool in aiToolsGenerateFor) {
      buffer.writeln('  - $tool');
    }
    return buffer.toString();
  }

  ValentyConfigModel copyWith({
    String? version,
    String? projectName,
    String? projectType,
    String? pyramidModel,
    List<String>? pyramidLevels,
    String? fixtureSetupPattern,
    String? testDoublesPattern,
    String? testOrganization,
    String? dslOutputDirectory,
    String? language,
    bool? aiToolsAutoDetect,
    List<String>? aiToolsGenerateFor,
  }) {
    return ValentyConfigModel(
      version: version ?? this.version,
      projectName: projectName ?? this.projectName,
      projectType: projectType ?? this.projectType,
      pyramidModel: pyramidModel ?? this.pyramidModel,
      pyramidLevels: pyramidLevels ?? this.pyramidLevels,
      fixtureSetupPattern: fixtureSetupPattern ?? this.fixtureSetupPattern,
      testDoublesPattern: testDoublesPattern ?? this.testDoublesPattern,
      testOrganization: testOrganization ?? this.testOrganization,
      dslOutputDirectory: dslOutputDirectory ?? this.dslOutputDirectory,
      language: language ?? this.language,
      aiToolsAutoDetect: aiToolsAutoDetect ?? this.aiToolsAutoDetect,
      aiToolsGenerateFor: aiToolsGenerateFor ?? this.aiToolsGenerateFor,
    );
  }
}
