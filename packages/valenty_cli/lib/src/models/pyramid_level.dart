enum PyramidLevel {
  unit('Unit', 'test/unit'),
  narrowIntegration('Narrow Integration', 'test/narrow_integration'),
  broadIntegration('Broad Integration', 'test/broad_integration'),
  contract('Contract', 'test/contract'),
  component('Component', 'test/component'),
  endToEnd('End-to-End', 'test/e2e'),
  acceptance('Acceptance', 'test/acceptance'),
  exploratory('Exploratory', 'test/exploratory');

  const PyramidLevel(this.displayName, this.testDirectory);

  final String displayName;
  final String testDirectory;
}
