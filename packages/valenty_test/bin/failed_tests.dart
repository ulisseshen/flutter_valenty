// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Runs Flutter tests and outputs ONLY the failures in a concise format.
///
/// Designed for AI agents: when you have thousands of tests, this script
/// filters out passing tests and returns only failures with file, test name,
/// error message, and stack trace. Saves context window tokens.
///
/// Usage:
///   dart run valenty_test:failed_tests [scope] [path]
///
/// Scopes:
///   all          — run all tests (default)
///   valenty      — run test/valenty/ only
///   unit         — auto-discover: test/unit/
///   acceptance   — auto-discover: test/acceptance/
///   widget       — auto-discover: test/ui/ or test/widget/
///   model        — auto-discover: test/models/ or test/model/
///   integration  — auto-discover: test/integration/
///   path         — run a specific file or directory
///
/// Examples:
///   dart run valenty_test:failed_tests
///   dart run valenty_test:failed_tests valenty
///   dart run valenty_test:failed_tests unit
///   dart run valenty_test:failed_tests path test/ui/pages/

const _red = '\x1B[31m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _cyan = '\x1B[36m';
const _dim = '\x1B[2m';
const _bold = '\x1B[1m';
const _reset = '\x1B[0m';

/// Named scopes mapped to possible directory paths (first match wins)
const _namedScopes = <String, List<String>>{
  'valenty': ['test/valenty/'],
  'unit': ['test/unit/'],
  'acceptance': ['test/acceptance/'],
  'widget': ['test/ui/', 'test/widget/', 'test/widgets/'],
  'model': ['test/models/', 'test/model/'],
  'integration': ['test/integration/'],
  'data': ['test/data/'],
  'service': ['test/services/', 'test/service/'],
  'controller': ['test/controllers/', 'test/controller/'],
};

class _Suite {
  final int id;
  final String path;
  _Suite({required this.id, required this.path});
}

class _Test {
  final int id;
  final String name;
  final int suiteId;
  final String? url;
  final int? line;
  _Test({
    required this.id,
    required this.name,
    required this.suiteId,
    this.url,
    this.line,
  });
}

class _Failure {
  final _Test test;
  final _Suite suite;
  final String error;
  final String stackTrace;
  final bool isFailure; // true = assertion failure, false = runtime error
  _Failure({
    required this.test,
    required this.suite,
    required this.error,
    required this.stackTrace,
    required this.isFailure,
  });
}

void main(List<String> args) async {
  final scope = args.isEmpty ? 'all' : args[0];
  final testPath = _resolveTestPath(scope, args);

  if (testPath != null && !_pathExists(testPath)) {
    print('${_red}ERROR$_reset: Path does not exist: $testPath');
    _printAvailableDirectories();
    exit(1);
  }

  print('${_cyan}Running Flutter tests...$_reset');
  print(
    '${_dim}Scope: $scope${testPath != null ? ' ($testPath)' : ''}$_reset',
  );
  print('');

  final arguments = ['test', '--machine'];
  if (testPath != null) arguments.add(testPath);

  final process = await Process.start('flutter', arguments);

  final suites = <int, _Suite>{};
  final tests = <int, _Test>{};
  final errors = <int, List<Map<String, dynamic>>>{};
  final failures = <_Failure>[];
  var totalTests = 0;
  var passedTests = 0;
  var skippedTests = 0;
  var failedTests = 0;

  await process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((
    line,
  ) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('{')) return;

    Map<String, dynamic> event;
    try {
      event = jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = event['type'] as String?;

    switch (type) {
      case 'suite':
        final suite = event['suite'] as Map<String, dynamic>;
        final id = suite['id'] as int;
        final path = suite['path'] as String? ?? 'unknown';
        suites[id] = _Suite(id: id, path: path);

      case 'testStart':
        final test = event['test'] as Map<String, dynamic>;
        final id = test['id'] as int;
        final name = test['name'] as String? ?? 'unknown';
        final suiteId = test['suiteID'] as int;
        final url = test['url'] as String?;
        final testLine = test['line'] as int?;
        tests[id] = _Test(
          id: id,
          name: name,
          suiteId: suiteId,
          url: url,
          line: testLine,
        );

      case 'error':
        final testId = event['testID'] as int;
        final error = event['error'] as String? ?? '';
        final stackTrace = event['stackTrace'] as String? ?? '';
        final isFailure = event['isFailure'] as bool? ?? false;
        errors.putIfAbsent(testId, () => []);
        errors[testId]!.add({
          'error': error,
          'stackTrace': stackTrace,
          'isFailure': isFailure,
        });

      case 'testDone':
        final testId = event['testID'] as int;
        final result = event['result'] as String?;
        final hidden = event['hidden'] as bool? ?? false;
        final skipped = event['skipped'] as bool? ?? false;

        if (hidden) break;

        totalTests++;

        if (skipped) {
          skippedTests++;
        } else if (result == 'success') {
          passedTests++;
        } else {
          failedTests++;
          final test = tests[testId];
          if (test != null) {
            final suite = suites[test.suiteId];
            final testErrors = errors[testId] ?? [];
            final errorMsg =
                testErrors.map((e) => e['error'] as String).join('\n');
            final stackTrace =
                testErrors.map((e) => e['stackTrace'] as String).join('\n');
            final isFailure = testErrors.any((e) => e['isFailure'] == true);
            failures.add(
              _Failure(
                test: test,
                suite: suite ?? _Suite(id: -1, path: 'unknown'),
                error: errorMsg,
                stackTrace: stackTrace,
                isFailure: isFailure,
              ),
            );
          }
        }
    }
  });

  final stderrOutput = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;

  _printSummary(
    total: totalTests,
    passed: passedTests,
    failed: failedTests,
    skipped: skippedTests,
    failures: failures,
    stderrOutput: stderrOutput,
    exitCode: exitCode,
  );

  exit(failures.isEmpty && exitCode == 0 ? 0 : 1);
}

String? _resolveTestPath(String scope, List<String> args) {
  switch (scope) {
    case 'all':
      return null;
    case 'path':
      if (args.length < 2) {
        print('${_red}ERROR$_reset: "path" scope requires a path argument');
        print('Usage: dart run valenty_test:failed_tests path test/some/path/');
        exit(1);
      }
      return args[1];
    default:
      if (_namedScopes.containsKey(scope)) {
        final candidates = _namedScopes[scope]!;
        for (final candidate in candidates) {
          if (_pathExists(candidate)) return candidate;
        }
        print('${_red}ERROR$_reset: No directory found for scope "$scope"');
        print('Looked for: ${candidates.join(', ')}');
        _printAvailableDirectories();
        exit(1);
      }

      if (_pathExists(scope)) return scope;

      print('${_red}ERROR$_reset: Unknown scope "$scope"');
      print('Valid scopes: ${_namedScopes.keys.join(', ')}');
      print('Or use: path <test/some/path/>');
      _printAvailableDirectories();
      exit(1);
  }
}

bool _pathExists(String path) {
  return Directory(path).existsSync() || File(path).existsSync();
}

void _printAvailableDirectories() {
  final testDir = Directory('test');
  if (!testDir.existsSync()) {
    print('\n${_yellow}No test/ directory found in current project$_reset');
    return;
  }

  final subdirs = testDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path)
      .toList()
    ..sort();

  if (subdirs.isNotEmpty) {
    print('\n${_cyan}Available test directories:$_reset');
    for (final dir in subdirs) {
      print('  $dir');
    }
  }
}

void _printSummary({
  required int total,
  required int passed,
  required int failed,
  required int skipped,
  required List<_Failure> failures,
  required String stderrOutput,
  required int exitCode,
}) {
  print('$_bold${'=' * 60}$_reset');
  print('$_bold  VALENTY TEST RESULTS$_reset');
  print('$_bold${'=' * 60}$_reset');
  print('');

  if (total == 0 && exitCode != 0) {
    print('${_red}COMPILATION ERROR — no tests executed$_reset');
    print('');
    if (stderrOutput.isNotEmpty) {
      final compileErrors = _extractCompileErrors(stderrOutput);
      print(compileErrors);
    }
    print('');
    print('$_bold${'=' * 60}$_reset');
    return;
  }

  final passedStr = '$_green$passed passed$_reset';
  final failedStr =
      failed > 0 ? '$_red$failed failed$_reset' : '$_dim$failed failed$_reset';
  final skippedStr = skipped > 0
      ? '$_yellow$skipped skipped$_reset'
      : '$_dim$skipped skipped$_reset';
  print('  Total: $total | $passedStr | $failedStr | $skippedStr');
  print('');

  if (failures.isEmpty) {
    print('$_green  ALL TESTS PASSED$_reset');
    print('$_bold${'=' * 60}$_reset');
    return;
  }

  print('$_red  FAILURES:$_reset');
  print('');

  for (var i = 0; i < failures.length; i++) {
    final f = failures[i];
    final label = f.isFailure ? 'FAIL' : 'ERROR';
    final color = f.isFailure ? _red : _yellow;

    print('$color--- $label ${i + 1}/${failures.length} ---$_reset');
    print('${_bold}File:$_reset ${f.suite.path}');
    print('${_bold}Test:$_reset ${f.test.name}');
    if (f.test.line != null) {
      print('${_dim}Line: ${f.test.line}$_reset');
    }
    print('${_bold}Error:$_reset');

    final errorLines = f.error.split('\n');
    final displayLines =
        errorLines.length > 20 ? errorLines.sublist(0, 20) : errorLines;
    for (final line in displayLines) {
      print('  $line');
    }
    if (errorLines.length > 20) {
      print('  $_dim... (${errorLines.length - 20} more lines)$_reset');
    }

    if (f.stackTrace.isNotEmpty) {
      final stackLines = f.stackTrace
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .where(
            (l) =>
                !l.contains('package:test/') &&
                !l.contains('package:test_api/') &&
                !l.contains('dart:async'),
          )
          .take(8)
          .toList();
      if (stackLines.isNotEmpty) {
        print('${_dim}Stack:$_reset');
        for (final line in stackLines) {
          print('  $_dim$line$_reset');
        }
      }
    }
    print('');
  }

  final uniqueFiles = failures.map((f) => f.suite.path).toSet().toList();
  print('${_bold}Re-run failed files:$_reset');
  for (final file in uniqueFiles) {
    print('  flutter test $file');
  }
  print('');
  print('$_bold${'=' * 60}$_reset');
}

String _extractCompileErrors(String stderr) {
  final lines = stderr.split('\n');
  final buffer = StringBuffer();
  var collecting = false;
  var count = 0;

  for (final line in lines) {
    if (line.contains('Error:') ||
        line.contains('error:') ||
        line.contains('Could not') ||
        line.contains('Target of')) {
      collecting = true;
      count = 0;
    }

    if (collecting) {
      buffer.writeln('  $line');
      count++;
      if (count > 5 && !line.contains('Error:') && !line.contains('error:')) {
        collecting = false;
      }
    }
  }

  final result = buffer.toString().trim();
  if (result.isEmpty) {
    final tail = lines.length > 15 ? lines.sublist(lines.length - 15) : lines;
    return tail.map((l) => '  $l').join('\n');
  }
  return result;
}
