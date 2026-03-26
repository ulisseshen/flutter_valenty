enum AiToolType {
  claude('Claude Code', '.claude/'),
  cursor('Cursor', '.cursor/'),
  codex('Codex', 'AGENTS.md'),
  openCode('OpenCode', '.opencode/');

  const AiToolType(this.displayName, this.configPath);

  final String displayName;
  final String configPath;
}
