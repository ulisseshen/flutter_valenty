#!/usr/bin/env node

import { existsSync, mkdirSync, cpSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { homedir } from 'os';

const __dirname = dirname(fileURLToPath(import.meta.url));
const templates = join(__dirname, '..', 'templates');
const home = homedir();

const BOLD = '\x1b[1m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const DIM = '\x1b[2m';
const RESET = '\x1b[0m';

function detect() {
  const tools = [];

  // Claude Code
  const claudeDir = join(home, '.claude');
  if (existsSync(claudeDir)) {
    tools.push({ name: 'Claude Code', id: 'claude', dir: claudeDir });
  }

  // Antigravity
  const antigravityDir = join(home, '.gemini', 'antigravity');
  const agentDir = join(home, '.gemini');
  if (existsSync(antigravityDir) || existsSync(agentDir)) {
    tools.push({ name: 'Antigravity', id: 'antigravity', dir: antigravityDir });
  }

  // Cursor
  const cursorDir = join(home, '.cursor');
  if (existsSync(cursorDir)) {
    tools.push({ name: 'Cursor', id: 'cursor', dir: cursorDir });
  }

  return tools;
}

function installClaude(claudeDir) {
  const commandsDir = join(claudeDir, 'commands', 'valenty');
  const workflowsDir = join(claudeDir, 'valenty', 'workflows');

  mkdirSync(commandsDir, { recursive: true });
  mkdirSync(workflowsDir, { recursive: true });

  // Copy commands
  const cmdSrc = join(templates, 'claude', 'commands', 'valenty');
  if (existsSync(cmdSrc)) {
    cpSync(cmdSrc, commandsDir, { recursive: true });
  }

  // Copy workflows
  const wfSrc = join(templates, 'claude', 'workflows');
  if (existsSync(wfSrc)) {
    cpSync(wfSrc, workflowsDir, { recursive: true });
  }

  const commands = existsSync(cmdSrc)
    ? readdirSync(cmdSrc).filter(f => f.endsWith('.md')).map(f => `/valenty:${f.replace('.md', '')}`)
    : [];

  return commands;
}

function installAntigravity(antigravityDir) {
  const workflowsDir = join(antigravityDir, 'global_workflows');
  const skillsDir = join(antigravityDir, 'skills', 'valenty-test');

  mkdirSync(workflowsDir, { recursive: true });
  mkdirSync(skillsDir, { recursive: true });

  // Copy workflows
  const wfSrc = join(templates, 'antigravity', 'workflows');
  if (existsSync(wfSrc)) {
    cpSync(wfSrc, workflowsDir, { recursive: true });
  }

  // Copy skills
  const skSrc = join(templates, 'antigravity', 'skills', 'valenty-test');
  if (existsSync(skSrc)) {
    cpSync(skSrc, skillsDir, { recursive: true });
  }

  const commands = existsSync(wfSrc)
    ? readdirSync(wfSrc).filter(f => f.endsWith('.md')).map(f => `/${f.replace('.md', '')}`)
    : [];

  return commands;
}

function installCursor(cursorDir) {
  const commandsDir = join(cursorDir, 'commands');
  const skillsDir = join(cursorDir, 'skills', 'valenty-test');

  mkdirSync(commandsDir, { recursive: true });
  mkdirSync(skillsDir, { recursive: true });

  // Copy commands
  const cmdSrc = join(templates, 'cursor', 'commands');
  if (existsSync(cmdSrc)) {
    cpSync(cmdSrc, commandsDir, { recursive: true });
  }

  // Copy skills
  const skSrc = join(templates, 'cursor', 'skills', 'valenty-test');
  if (existsSync(skSrc)) {
    cpSync(skSrc, skillsDir, { recursive: true });
  }

  const commands = existsSync(cmdSrc)
    ? readdirSync(cmdSrc).filter(f => f.endsWith('.md')).map(f => `/${f.replace('.md', '')}`)
    : [];

  return commands;
}

// ── Main ─────────────────────────────────────────────────

console.log('');
console.log(`${BOLD}Valenty${RESET} — AI-powered test writing for Flutter`);
console.log('');

const tools = detect();

if (tools.length === 0) {
  console.log(`${YELLOW}No AI coding tools detected.${RESET}`);
  console.log('');
  console.log('Valenty supports: Claude Code, Antigravity, Cursor');
  console.log('Install one of these tools first, then re-run:');
  console.log(`  ${DIM}npx valenty-tester@latest${RESET}`);
  process.exit(0);
}

console.log(`Detected: ${tools.map(t => t.name).join(', ')}`);
console.log('');

let installed = 0;

for (const tool of tools) {
  process.stdout.write(`Installing for ${tool.name}...`);

  let commands = [];
  try {
    switch (tool.id) {
      case 'claude':
        commands = installClaude(tool.dir);
        break;
      case 'antigravity':
        commands = installAntigravity(tool.dir);
        break;
      case 'cursor':
        commands = installCursor(tool.dir);
        break;
    }
    console.log(` ${GREEN}done${RESET}`);
    if (commands.length > 0) {
      console.log(`  ${DIM}Commands: ${commands.join(', ')}${RESET}`);
    }
    installed++;
  } catch (err) {
    console.log(` ${YELLOW}failed${RESET}`);
    console.log(`  ${DIM}${err.message}${RESET}`);
  }
}

console.log('');

if (installed > 0) {
  console.log(`${GREEN}${BOLD}Valenty installed for ${installed} tool${installed > 1 ? 's' : ''}.${RESET}`);
  console.log('');
  console.log('Next step — open your AI tool and run:');
  console.log('');
  console.log(`  ${BOLD}/valenty:init${RESET}  ${DIM}(Claude Code)${RESET}`);
  console.log(`  ${BOLD}/valenty-init${RESET}  ${DIM}(Antigravity / Cursor)${RESET}`);
  console.log('');
  console.log(`This will add ${BOLD}valenty_test${RESET} to your Flutter project`);
  console.log('and generate your first test scenarios.');
}

console.log('');
