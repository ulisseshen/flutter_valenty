enum ProjectType {
  dartPackage,
  flutterApp,
  flutterPackage,
  flutterPlugin,
}

class ProjectInfo {
  const ProjectInfo({
    required this.name,
    required this.type,
    required this.path,
    required this.dependencies,
    required this.devDependencies,
    required this.hasFlutter,
    this.dartSdkConstraint,
  });

  final String name;
  final ProjectType type;
  final String path;
  final List<String> dependencies;
  final List<String> devDependencies;
  final bool hasFlutter;
  final String? dartSdkConstraint;
}
