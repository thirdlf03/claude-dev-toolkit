---
name: claude-code-subagent-builder
description: Create, edit, or audit Claude Code custom agents (subagents), including file locations, YAML frontmatter, tool/permission settings, skills preloading, and prompt design. Use when asked to define a new Claude Code subagent, update an existing one, or review subagent configs for correctness and best practices. Triggers on "create agent", "new subagent", "define custom agent", "audit agent".
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
---

# Claude Code Subagent Builder

Define and refine Claude Code subagents with correct placement, frontmatter, and prompting so delegation is safe, fast, and predictable.

## Usage

```
"Create a subagent for code review"
"Define a new agent for log analysis"
"Audit my existing subagents"
```

## Workflow

1. Clarify the subagent's goal, inputs, outputs, and success criteria.
2. Choose the scope and location for the subagent file.
3. Draft YAML frontmatter and the system prompt body.
4. Constrain tools and permissions; add skills or hooks only when needed.
5. Test with real tasks and iterate.

## Requirements Intake

Ask for:
| Question | Purpose |
|----------|---------|
| Primary tasks + 2-3 examples | Define scope |
| Expected output format | Set quality bar |
| Scope (user/project/session) | Choose location |
| Tool access needs | Security |
| Permission mode | Safety |
| Skills to preload | Capabilities |
| Hooks needed | Automation |
| Display color | UX |

## Choose Scope and Location

| Scope | Location | Use Case |
|-------|----------|----------|
| Session | `--agents` CLI JSON | Temporary, experiments |
| Project | `.claude/agents/` | Repo-specific, team use |
| User | `~/.claude/agents/` | Personal workflows |

**Reload after edits**: restart or use `/agents` command.

## Author the Subagent File

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| name | Yes | Unique, short, action-oriented |
| description | Yes | Routing hint (WHEN to use) |
| tools | Recommended | Allowlist, `[]` for none, omit for all |
| disallowedTools | Optional | Denylist |
| model | Optional | Override model |
| permissionMode | Optional | default/acceptEdits/dontAsk/bypassPermissions/plan |
| skills | Optional | Skills to preload |
| hooks | Optional | Hooks to run |
| color | Optional | cyan/blue/green/magenta/yellow/red/white |
| disabled | Optional | Set true to disable |

### Template

```markdown
---
name: example-helper
description: Handle concise summaries of logs and errors for quick triage.
tools: ["Read", "Grep", "Glob"]
permissionMode: default
color: cyan
---

You are a focused helper that:
- Summarizes error patterns and likely root causes.
- Calls tools only when evidence is needed.
- Outputs a short summary followed by 3-5 bullet findings.

## Constraints
- Maximum 500 tokens output
- Never modify files

## Output Format
1. Summary (1-2 sentences)
2. Findings (3-5 bullets)
3. Recommended next steps
```

## Prompting Guidance

| Do | Don't |
|----|-------|
| Include all constraints explicitly | Assume inherited global instructions |
| Specify output format | Leave format ambiguous |
| State when to use/avoid tools | Let agent decide freely |
| Include acceptance criteria | Skip validation criteria |

## Tooling and Permissions

| Pattern | When to Use |
|---------|-------------|
| `tools: []` | Analysis-only, no file access |
| `tools: ["Read", "Glob"]` | Read-only inspection |
| `disallowedTools: ["Bash"]` | Remove risky tools |
| `permissionMode: default` | Standard safety (recommended) |
| `permissionMode: dontAsk` | Non-tooling analysis only |
| `permissionMode: plan` | Mandatory plan before tools |

**Avoid**: `bypassPermissions` unless hooks require it in trusted environment.

## Test and Iterate

### Test Checklist

| Check | Pass Criteria |
|-------|---------------|
| Format consistency | Output matches specified format |
| Tool usage | Uses only necessary tools |
| Constraint adherence | Respects all stated limits |
| Error handling | Graceful failure on edge cases |

### Example Test Tasks

```
# For a code-review agent:
"Review the changes in src/components/Button.tsx"

# For a log-analysis agent:
"Summarize errors from the last 24 hours in app.log"

# For a documentation agent:
"Generate API docs for the UserService class"
```

## Error Handling

| Issue | Solution |
|-------|----------|
| Agent file not found | Check path, suggest correct location |
| Invalid YAML | Report parse error with line number |
| Missing required field | List missing fields, provide template |
| Permission denied | Check file permissions, suggest chmod |
| Agent not loading | Verify frontmatter syntax, restart Claude |

## References

- [references/claude-code-subagents.md](references/claude-code-subagents.md) - Field reference, scopes, permissions
