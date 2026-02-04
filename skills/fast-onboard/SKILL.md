---
name: fast-onboard
description: Analyzes repository structure and generates CLAUDE.md documentation. Use when user mentions "onboard", "analyze project", "understand codebase", "project structure", or when working with new/unfamiliar repositories.
allowed-tools:
  - Bash
  - Read
  - Task
  - Glob
model: haiku
---

# Fast Onboard

Rapidly analyzes new projects and generates comprehensive CLAUDE.md documentation.

## Prerequisites

**Required tools**:
- `jq` (JSON processor) - **Fatal if missing**

**Recommended tools**:
- `scc` (code stats)
- `fd` (file finder)
- `tree` (directory structure)

**Required subagent**:
- `.claude/agents/repo-analyzer.md` - Generates CLAUDE.md from collected data

## Workflow

### Step 1: Collect Project Statistics

```bash
bash .claude/skills/fast-onboard/scripts/cached_collect.sh
```

### Step 2: Launch repo-analyzer

```
Task(
  subagent_type: "repo-analyzer",
  prompt: "Analyze the project data in .claude/.onboard-cache.json and generate CLAUDE.md"
)
```

See [reference.md](./reference.md) for the detailed prompt template.

## Input / Output

| Stage | Input | Output |
|-------|-------|--------|
| Collect | Repository files | `.claude/.onboard-cache.json` |
| Analyze | JSON statistics | `CLAUDE.md` |

## Error Handling

| Condition | Behavior |
|-----------|----------|
| `jq` missing | **Fatal** - Script exits with error |
| `scc` missing | `codeStats` = `null`, warning logged |
| `fd` missing | File counts = `null`, warning logged |
| `tree` missing | `structure` = empty array, warning logged |
| repo-analyzer missing | Report error, suggest creating subagent |
| Cache read error | Force fresh collection |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FAST_ONBOARD_FORCE` | Bypass cache, force fresh collection | `0` |
| `FAST_ONBOARD_CACHE_SECONDS` | Cache TTL in seconds | `3600` |

## References

- [reference.md](./reference.md) - JSON structure details, prompt template
- [templates/CLAUDE.md.template](./templates/CLAUDE.md.template) - Output template

## Usage

```
/fast-onboard
```

Or naturally: "analyze this project", "help me understand this codebase"
