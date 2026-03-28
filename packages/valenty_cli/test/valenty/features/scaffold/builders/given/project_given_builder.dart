import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart' show addTearDown;
import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/scaffold_when_builder.dart';
import 'scaffold_given_builder.dart';

/// Builder for setting up a temporary project in the Given phase.
///
/// Available methods:
/// - `.withName(String)` — set the project name
/// - `.withType(String)` — set the project type ('dart' or 'flutter_app')
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class ProjectGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ProjectGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _name = 'test_project';
  String _type = 'dart';

  ProjectGivenBuilder withName(String name) {
    _name = name;
    return this;
  }

  ProjectGivenBuilder withType(String type) {
    _type = type;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final tempDir =
        Directory.systemTemp.createTempSync('valenty_scaffold_test_');
    ctx.set('projectPath', tempDir.path);
    ctx.set('tempDir', tempDir);

    // Register cleanup for the temp directory
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // Write a minimal pubspec.yaml
    final pubspecContent = '''
name: $_name
description: A test project.
version: 1.0.0

environment:
  sdk: ^3.5.0
''';

    if (_type == 'flutter_app') {
      // Add flutter dependency for flutter_app type
      final flutterPubspec = '''
name: $_name
description: A test Flutter project.
version: 1.0.0

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
''';
      File(p.join(tempDir.path, 'pubspec.yaml'))
          .writeAsStringSync(flutterPubspec);
    } else {
      File(p.join(tempDir.path, 'pubspec.yaml'))
          .writeAsStringSync(pubspecContent);
    }

    // Create lib directory
    Directory(p.join(tempDir.path, 'lib')).createSync(recursive: true);
  }

  /// Transition to When phase.
  ScaffoldWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return ScaffoldWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  ScaffoldGivenBuilder get and {
    final finalized = finalizeStep();
    return ScaffoldGivenBuilder(finalized);
  }
}
