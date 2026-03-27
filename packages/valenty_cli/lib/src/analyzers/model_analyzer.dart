import 'dart:io';

/// Information about a single field in a Dart model class.
class FieldInfo {
  const FieldInfo({required this.name, required this.type});

  final String name;
  final String type;

  /// The Dart default value for this type.
  String get defaultValue {
    switch (type) {
      case 'String':
        return "''";
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return 'false';
      case 'num':
        return '0';
      default:
        if (type.endsWith('?')) return 'null';
        if (type.startsWith('List')) return 'const []';
        if (type.startsWith('Map')) return 'const {}';
        if (type.startsWith('Set')) return 'const {}';
        return "'' /* TODO: provide default for $type */";
    }
  }

  /// PascalCase version of the field name (for method names like withUnitPrice).
  String get pascalCase {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }
}

/// Information about a parsed Dart model class.
class ModelInfo {
  const ModelInfo({
    required this.className,
    required this.fields,
    this.isAbstract = false,
  });

  final String className;
  final List<FieldInfo> fields;

  /// Whether the class was declared with the `abstract` keyword.
  final bool isAbstract;

  /// camelCase version of the class name.
  String get camelCase {
    if (className.isEmpty) return className;
    return className[0].toLowerCase() + className.substring(1);
  }

  /// snake_case version of the class name.
  String get snakeCase {
    return className
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

/// Regex-based Dart model parser.
///
/// Extracts class names and fields from Dart source files by parsing
/// final field declarations and constructor parameters.
class ModelAnalyzer {
  /// Parse a single Dart source file and return all model classes found.
  List<ModelInfo> parseFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }
    return parseSource(file.readAsStringSync());
  }

  /// Parse Dart source code and return all model classes found.
  List<ModelInfo> parseSource(String source) {
    final models = <ModelInfo>[];

    // Strip single-line and multi-line comments so they don't interfere
    // with field/class parsing.
    final cleanSource = _stripComments(source);

    // Match class declarations, including abstract classes.
    // Skips enum declarations.
    final classPattern = RegExp(
      r'(abstract\s+)?class\s+(\w+)\s*'
      r'(?:extends\s+\w+(?:<[^>]*>)?\s*)?'
      r'(?:implements\s+[\w,\s<>]+\s*)?'
      r'(?:with\s+[\w,\s<>]+\s*)?\{',
    );

    // Also detect enums so we can skip them.
    final enumPattern = RegExp(r'enum\s+(\w+)\s*\{');
    final enumNames = enumPattern
        .allMatches(cleanSource)
        .map((m) => m.group(1)!)
        .toSet();

    for (final classMatch in classPattern.allMatches(cleanSource)) {
      final isAbstract = classMatch.group(1) != null;
      final className = classMatch.group(2)!;
      final classStart = classMatch.end;

      // Skip enum classes (e.g. `enum Foo { ... }` that got matched)
      if (enumNames.contains(className)) continue;

      // Find the matching closing brace for this class
      final classBody = _extractClassBody(cleanSource, classStart);
      if (classBody == null) continue;

      final fields = <FieldInfo>[];

      // Strategy 1: Parse final field declarations.
      // Supports generics with nested angle brackets (e.g. Map<String, List<int>>),
      // nullable types (String?), and skips static/private fields.
      // Also skips fields with default values assigned via `=`.
      final fieldPattern = RegExp(
        r'^\s+final\s+(' + _typePatternStr + r')\s+(\w+)\s*[;=]',
        multiLine: true,
      );
      for (final fieldMatch in fieldPattern.allMatches(classBody)) {
        final rawType = fieldMatch.group(1)!.trim();
        final name = fieldMatch.group(2)!;
        // Skip private fields
        if (name.startsWith('_')) continue;
        // Parse the type, which may have extra whitespace from regex
        final type = _normalizeType(rawType);
        fields.add(FieldInfo(name: name, type: type));
      }

      // Filter out static fields that accidentally matched `final`.
      fields.removeWhere((field) {
        // Check if there's a `static ... fieldName` in the class body
        final staticCheck = RegExp(
          r'^\s+static\s+(?:const\s+|final\s+)?(?:' +
              _typePatternStr +
              r'\s+)?' +
              RegExp.escape(field.name) +
              r'\s*[;=]',
          multiLine: true,
        );
        return staticCheck.hasMatch(classBody);
      });

      // Strategy 2: If no final fields found, try constructor parameters
      if (fields.isEmpty) {
        final constructorFields =
            _parseConstructorParams(classBody, className);
        fields.addAll(constructorFields);
      }

      if (fields.isNotEmpty) {
        models.add(ModelInfo(
          className: className,
          fields: fields,
          isAbstract: isAbstract,
        ),);
      }
    }

    return models;
  }

  /// Pattern string for matching Dart types including generics with nesting.
  ///
  /// Matches: `String`, `int?`, `List<Product>`, `Map<String, int>`,
  /// `Future<Order?>`, `Map<String, List<int>>`, etc.
  static const _typePatternStr =
      r'[\w]+(?:<[\w<>,?\s]+>)?\??';

  /// Extract the body of a class (everything between { and matching }).
  String? _extractClassBody(String source, int startAfterBrace) {
    var depth = 1;
    var i = startAfterBrace;
    while (i < source.length && depth > 0) {
      if (source[i] == '{') {
        depth++;
      } else if (source[i] == '}') {
        depth--;
      }
      i++;
    }
    if (depth != 0) return null;
    return source.substring(startAfterBrace, i - 1);
  }

  /// Parse constructor parameters to extract field info.
  ///
  /// Handles multiline constructors by using brace-counting to extract the
  /// full parameter block rather than relying on `[^}]*`.
  List<FieldInfo> _parseConstructorParams(String classBody, String className) {
    final fields = <FieldInfo>[];

    // Find the constructor opening: ClassName( or const ClassName(
    final constructorStart = RegExp(
      r'(?:const\s+)?' + RegExp.escape(className) + r'\s*\(',
    );

    final startMatch = constructorStart.firstMatch(classBody);
    if (startMatch == null) return fields;

    // Extract everything inside the outer parentheses using paren-counting,
    // which handles multiline constructors correctly.
    final parenContent = _extractBracketedContent(
      classBody,
      startMatch.end - 1, // position of the '('
      '(',
      ')',
    );
    if (parenContent == null) return fields;

    // Now find the named parameter block inside { ... }
    final braceStart = parenContent.indexOf('{');
    if (braceStart == -1) return fields;

    final paramsBlock = _extractBracketedContent(
      parenContent,
      braceStart,
      '{',
      '}',
    );
    if (paramsBlock == null) return fields;

    // Match parameters like:
    //   required this.name
    //   required this.unitPrice
    //   this.name = 'default'
    //   required String this.name
    //   required List<Product> this.items
    final paramPattern = RegExp(
      '(?:required\\s+)?'
      '(?:($_typePatternStr)\\s+)?'
      r'this\.(\w+)'
      r'(?:\s*=\s*[^,}]+)?',
    );

    for (final paramMatch in paramPattern.allMatches(paramsBlock)) {
      final explicitType = paramMatch.group(1)?.trim();
      final name = paramMatch.group(2)!;

      if (name.startsWith('_')) continue;

      // If there's an explicit type, use it. Otherwise try to find the
      // field declaration in the class body.
      String type;
      if (explicitType != null && explicitType.isNotEmpty) {
        type = _normalizeType(explicitType);
      } else {
        type = _findFieldType(classBody, name) ?? 'dynamic';
      }

      fields.add(FieldInfo(name: name, type: type));
    }

    return fields;
  }

  /// Find the type of a field by looking for its declaration in the class body.
  String? _findFieldType(String classBody, String fieldName) {
    final pattern = RegExp(
      r'(?:final\s+)?(' +
          _typePatternStr +
          r')\s+' +
          RegExp.escape(fieldName) +
          r'\s*[;=]',
    );
    final match = pattern.firstMatch(classBody);
    final raw = match?.group(1)?.trim();
    return raw != null ? _normalizeType(raw) : null;
  }

  /// Extract content inside matched brackets (parens, braces, angle brackets).
  /// [start] is the index of the opening bracket character.
  /// Returns the content between the brackets (exclusive), or null.
  String? _extractBracketedContent(
    String source,
    int start,
    String open,
    String close,
  ) {
    if (start >= source.length || source[start] != open) return null;
    var depth = 1;
    var i = start + 1;
    while (i < source.length && depth > 0) {
      if (source[i] == open) {
        depth++;
      } else if (source[i] == close) {
        depth--;
      }
      if (depth > 0) i++;
    }
    if (depth != 0) return null;
    return source.substring(start + 1, i);
  }

  /// Strip single-line (//) and multi-line (/* */) comments from source.
  ///
  /// This prevents comments from being parsed as fields or class declarations.
  String _stripComments(String source) {
    // Remove multi-line comments first (handles nested /** */ doc comments)
    var result = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    // Remove single-line comments (// ...) but preserve the newline
    result = result.replaceAll(RegExp(r'//[^\n]*'), '');
    return result;
  }

  /// Normalize whitespace in a type string.
  /// e.g. `Map< String , int >` becomes `Map<String, int>`.
  String _normalizeType(String type) {
    return type
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('< ', '<')
        .replaceAll(' >', '>')
        .replaceAll(' ,', ',')
        .replaceAll(', ', ', ')
        .trim();
  }
}
