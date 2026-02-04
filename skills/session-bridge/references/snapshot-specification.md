# Session Snapshot Specification

Format specification for session state snapshots.

> **Note**: Automatic snapshot creation is planned for a future version. This specification defines the format for manual snapshots.

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["timestamp", "project", "current_task"],
  "properties": {
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO8601 timestamp when snapshot was created"
    },
    "project": {
      "type": "string",
      "description": "Project name"
    },
    "current_task": {
      "type": "object",
      "required": ["description", "status"],
      "properties": {
        "description": {
          "type": "string",
          "description": "What the task is about"
        },
        "status": {
          "type": "string",
          "enum": ["pending", "in_progress", "blocked", "completed"],
          "description": "Current task status"
        },
        "files_modified": {
          "type": "array",
          "items": {"type": "string"},
          "description": "List of files being worked on"
        },
        "next_steps": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Remaining steps to complete"
        },
        "blockers": {
          "type": "array",
          "items": {"type": "string"},
          "description": "What's blocking progress"
        }
      }
    },
    "context": {
      "type": "object",
      "properties": {
        "relevant_observations": {
          "type": "array",
          "items": {"type": "number"},
          "description": "Memory observation IDs for context"
        },
        "key_decisions": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Important decisions made"
        },
        "learned_patterns": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Patterns discovered during work"
        }
      }
    },
    "uncommitted_changes": {
      "type": "number",
      "description": "Number of uncommitted files"
    },
    "branch": {
      "type": "string",
      "description": "Current VCS branch"
    }
  }
}
```

## Example Snapshot

```json
{
  "timestamp": "2026-02-04T14:30:00Z",
  "project": "test-fast-init",
  "current_task": {
    "description": "Implementing session-bridge skill for automatic resume detection",
    "status": "in_progress",
    "files_modified": [
      ".claude/skills/session-bridge/SKILL.md",
      ".claude/skills/session-bridge/scripts/collect_context.sh"
    ],
    "next_steps": [
      "Split workflow.md into multiple files",
      "Test script execution",
      "Configure SessionStart hook"
    ]
  },
  "context": {
    "relevant_observations": [1380, 1381, 1382],
    "key_decisions": [
      "Use 3-layer memory protocol for efficiency",
      "Support both git and jj version control"
    ]
  },
  "uncommitted_changes": 3,
  "branch": "main"
}
```

## Snapshot Location

**Project-local** (recommended):
```
.claude/session-snapshot.json
```

**Global** (for multi-project tracking):
```
~/.claude/snapshots/<project-name>-<timestamp>.json
```

## Usage

### Creating a Snapshot

Manually create a JSON file with the format above:

```bash
# Save to project directory
cat > .claude/session-snapshot.json << 'EOF'
{
  "timestamp": "2026-02-04T14:30:00Z",
  "project": "my-project",
  ...
}
EOF
```

### Loading a Snapshot

The session-bridge skill will automatically detect and load snapshots from:
1. `.claude/session-snapshot.json` (project-local)
2. `~/.claude/snapshots/<project-name>-*.json` (global, most recent)

### Snapshot Management Best Practices

1. **Save before ending sessions**
   - Capture state when stopping work
   - Include next_steps for easy resume

2. **Clean up old snapshots**
   - Delete snapshots after successful resume
   - Keep only recent snapshots (last 5)

3. **Include context references**
   - Link to relevant memory observations
   - Document key decisions made

## Future Enhancements

Planned features for automatic snapshot creation:

- **Auto-save on session end**: Automatically capture state when Claude Code exits
- **Smart snapshot triggers**: Create snapshots when significant milestones are reached
- **Snapshot restoration**: Interactive prompt to restore from snapshot on session start
- **Snapshot browser**: CLI tool to view and manage snapshots
