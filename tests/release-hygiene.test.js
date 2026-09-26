'use strict';

// Versions agree everywhere; the CHANGELOG has an entry for the current version; every skill has
// valid frontmatter whose name matches its folder; every reference file a SKILL.md names exists.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const read = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8');
const VERSION = read('VERSION').trim();

test('VERSION, plugin.json, marketplace.json and package.json agree', () => {
  assert.equal(JSON.parse(read('.claude-plugin/plugin.json')).version, VERSION);
  assert.equal(JSON.parse(read('.claude-plugin/marketplace.json')).plugins[0].version, VERSION);
  assert.equal(JSON.parse(read('package.json')).version, VERSION);
});

test('CHANGELOG has a heading for the current version in the format the hook parses', () => {
  assert.match(read('CHANGELOG.md'), new RegExp(`^## ${VERSION.replace(/\./g, '\\.')} — \\d{4}-\\d{2}-\\d{2}`, 'm'));
});

const skills = fs.readdirSync(path.join(ROOT, 'skills'));

test('every eval has all fields and names files that exist', () => {
  const evals = fs.readdirSync(path.join(ROOT, 'evals')).filter((f) => f.endsWith('.md') && f !== 'README.md');
  assert.ok(evals.length >= 20, `evals: ${evals.length}`);
  for (const f of evals) {
    const body = read(`evals/${f}`);
    for (const field of ['# Eval:', 'Skill under test:', 'Files:', 'Setup:', 'Expected (binary):', 'Failure looks like:', 'Last run:']) {
      assert.ok(body.includes(field), `${f}: missing "${field}"`);
    }
    const files = /^Files:\s+(.+)$/m.exec(body)[1].split(',').map((s) => s.trim()).filter(Boolean);
    for (const p of files) assert.ok(fs.existsSync(path.join(ROOT, p)), `${f}: ${p} does not exist`);
  }
});
const agents = fs.readdirSync(path.join(ROOT, 'agents')).filter((f) => f.endsWith('.md'));

test('every agent has YAML-safe frontmatter, a matching name, tools, and review roles cannot Write/Edit', () => {
  assert.ok(agents.length >= 4);
  for (const f of agents) {
    const fm = /^---\n([\s\S]*?)\n---/.exec(read(`agents/${f}`).replace(/\r\n/g, '\n'));
    assert.ok(fm, `${f}: frontmatter`);
    assert.match(fm[1], new RegExp(`^name: ${f.replace(/\.md$/, '')}$`, 'm'), `${f}: name`);
    const desc = /^description: (.+)$/m.exec(fm[1])?.[1] || '';
    assert.ok(desc.length >= 80, `${f}: description`);
    assert.doesNotMatch(desc, /: | #/, `${f}: YAML-breaking ": " or " #" in description`);
    const tools = /^tools: (.+)$/m.exec(fm[1])?.[1] || '';
    assert.ok(tools, `${f}: tools`);
    if (/checker|playtester|researcher/.test(f)) assert.doesNotMatch(tools, /\b(Write|Edit)\b/, `${f}: review role must not have Write/Edit`);
  }
});

test('every skill has frontmatter with a matching name and a description with triggers', () => {
  for (const s of skills) {
    const body = read(`skills/${s}/SKILL.md`);
    const fm = /^---\n([\s\S]*?)\n---/.exec(body.replace(/\r\n/g, '\n'));
    assert.ok(fm, `${s}: frontmatter`);
    assert.match(fm[1], new RegExp(`^name: ${s}$`, 'm'), `${s}: name`);
    assert.match(fm[1], /^description: .{80,}$/m, `${s}: description`);
    assert.match(fm[1], /Triggers/, `${s}: triggers`);
  }
});

// A plain YAML scalar breaks on ": " or " #". Claude Code then loads the skill with EMPTY metadata
// (no name, no description → never triggered) and says nothing at runtime. Found by
// `claude plugin validate` on 2026-09-25 in game-start ("orchestrator: runs").
test('skill descriptions contain no YAML-breaking ": " or " #" (includes the template spec-writing skill)', () => {
  const files = skills.map((s) => `skills/${s}/SKILL.md`).concat(['templates/ai/skills/spec-writing/SKILL.md']);
  for (const f of files) {
    const line = read(f).split(/\r?\n/).find((l) => l.startsWith('description: '));
    const value = line.slice('description: '.length);
    assert.doesNotMatch(value, /: /, `${f}: ": " in description`);
    assert.doesNotMatch(value, / #/, `${f}: " #" in description`);
  }
});

test('reference files named in a SKILL.md exist next to it', () => {
  for (const s of skills) {
    const dir = path.join(ROOT, 'skills', s);
    const body = read(`skills/${s}/SKILL.md`);
    for (const m of body.matchAll(/`([a-z0-9-]+\.md)`/g)) {
      if (['SKILL.md', 'AGENTS.md', 'CLAUDE.md', 'README.md', 'STATUS.md'].includes(m[1])) continue;
      const local = path.join(dir, m[1]);
      const sibling = skills.some((o) => fs.existsSync(path.join(ROOT, 'skills', o, m[1])));
      assert.ok(fs.existsSync(local) || sibling, `${s}: referenced ${m[1]} not found`);
    }
  }
});
