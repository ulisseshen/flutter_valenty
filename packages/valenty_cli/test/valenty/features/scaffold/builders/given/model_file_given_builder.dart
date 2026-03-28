import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:valenty_test/valenty_test.dart';

import '../when/scaffold_when_builder.dart';
import 'scaffold_given_builder.dart';

/// Builder for creating a model file in the Given phase.
///
/// Available methods:
/// - `.withClassName(String)` — set the class name
/// - `.withFields(Map<String, String>)` — set the fields
/// - `.atPath(String)` — set the file path relative to project root
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class ModelFileGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ModelFileGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _className = 'Model';
  Map<String, String> _fields = {};
  String _path = 'lib/models/model.dart';

  ModelFileGivenBuilder withClassName(String className) {
    _className = className;
    return this;
  }

  ModelFileGivenBuilder withFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  ModelFileGivenBuilder atPath(String path) {
    _path = path;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final projectPath = ctx.get<String>('projectPath');

    // Build the Dart class source
    final fieldDeclarations =
        _fields.entries.map((e) => '  final ${e.value} ${e.key};').join('\n');

    final constructorParams =
        _fields.entries.map((e) => '    required this.${e.key},').join('\n');

    final classSource = '''
class $_className {
  const $_className({
$constructorParams
  });

$fieldDeclarations
}
''';

    // Write the file
    final filePath = p.join(projectPath, _path);
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(classSource);

    // Store model paths as a list in context
    final List<String> modelPaths;
    if (ctx.has('modelPaths')) {
      modelPaths = ctx.get<List<String>>('modelPaths');
    } else {
      modelPaths = <String>[];
      ctx.set('modelPaths', modelPaths);
    }
    modelPaths.add(_path);
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
