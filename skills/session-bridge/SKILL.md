---
name: session-bridge
description: Automatically resume previous work by searching claude-mem for incomplete tasks, past decisions, and session context. Use when starting a session, continuing work, or when user says "resume", "continue", "前回", "再開", "続き", "what was I working on", or asks about previous work.
allowed-tools:
  - Bash
  - Read
---

# Session Bridge

Seamless session continuity through automatic resume detection, smart context inheritance, and session snapshots.

## Prerequisites

**Required**:
- MCP server: `claude-mem` with search tools (`search`, `timeline`, `get_observations`)
- Script: `.claude/skills/session-bridge/scripts/collect_context.sh`

**Error if missing**: Report which component is unavailable and provide setup instructions.

## Quick Start

### Resume Previous Work

```bash
# Collect current project context
bash .claude/skills/session-bridge/scripts/collect_context.sh
```

Then search memory using the 3-layer protocol (see References).

### Check Session Status

Ask: "前回の作業を確認して" or "What was I working on?"

## Trigger Conditions

This skill activates when:
- Starting a new session in a project with history
- Keywords: "resume", "continue", "前回", "再開", "続き", "what was I working on"
- Detecting uncommitted changes or in-progress work
- SessionStart hook provides context (if configured)

## Core Workflows

### 1. Auto Resume Detection

1. **Run context collector**:
   ```bash
   bash .claude/skills/session-bridge/scripts/collect_context.sh
   ```

2. **Search memory** using MCP tools:
   - `search()` → Get ID index
   - `timeline()` → Get context around results
   - `get_observations()` → Fetch full details

   See [memory-search-protocol.md](references/memory-search-protocol.md) for detailed usage.

### 2. Smart Context Injection

Retrieve relevant learning from past sessions:

| Query Pattern | Use Case |
|---------------|----------|
| `"bugfix <project>"` | Past bug fixes and solutions |
| `"decision <project>"` | Architectural decisions |
| `"<error message>"` | Similar error resolutions |
| `"<feature name>"` | Implementation history |

**Type filters**: `session-request`, `bugfix`, `decision`, `discovery`, `feature`

### 3. Session Snapshot

Save current state for later recovery. See [snapshot-specification.md](references/snapshot-specification.md) for format.

## SessionStart Hook (Optional)

Auto-inject context at session start.

**Quick Setup**:
```bash
claude hooks add SessionStart "bash .claude/skills/session-bridge/scripts/collect_context.sh"
```

**Manual Setup** - Edit `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/skills/session-bridge/scripts/collect_context.sh",
        "timeout": 10
      }]
    }]
  }
}
```

## Common Patterns

| Pattern | Steps |
|---------|-------|
| Resume Interrupted Work | collect_context → search recent sessions → find incomplete tasks → present options |
| Context-Aware Bug Fix | user reports bug → search similar bugs → inject solutions → apply patterns |
| Decision Recall | user asks "why X?" → search decisions → fetch observation → present context |

## Error Handling

| Issue | Solution |
|-------|----------|
| No memory results | Broaden dateStart, try different keywords, remove type filter |
| Too many results | Add project filter, narrow date range, use specific query |
| Script not found | Create script or use manual memory search |
| MCP server unavailable | Report error, suggest checking MCP configuration |

## Best Practices

1. **Always use 3-layer protocol** - search → timeline → get_observations
2. **Filter aggressively** - Use project and date filters
3. **Fetch selectively** - Only get_observations for relevant IDs
4. **Save snapshots** - Before ending complex work sessions

## References

- [memory-search-protocol.md](references/memory-search-protocol.md) - 3-layer MCP API usage and search parameters
- [resume-algorithm.md](references/resume-algorithm.md) - Step-by-step resume detection workflow
- [snapshot-specification.md](references/snapshot-specification.md) - Session snapshot format and schema
- [troubleshooting.md](references/troubleshooting.md) - Common issues and solutions
