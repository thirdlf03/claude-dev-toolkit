# Claude Code Subagents Quick Reference

## Table of Contents
- Locations and scope
- Loading and reload behavior
- Frontmatter fields
- Tools and permissions
- Skills and hooks
- Delegation patterns

## Locations and Scope
- Project subagents: `.claude/agents/`
- User subagents: `~/.claude/agents/`
- Session subagents: CLI `--agents` JSON with `project` and `user` paths

Claude Code loads project subagents before user subagents. Session configuration can override by pointing to specific directories.

Example session config:
```bash
claude --agents '{"project":".claude/agents","user":"~/.claude/agents"}'
```

## Loading and Reload Behavior
Subagents are loaded when a session starts. After adding or editing a subagent, reload them (restart or use `/agents`).

## Frontmatter Fields
Required:
- `name`: Unique identifier for routing and invocation.
- `description`: Routing hint that explains when to use the subagent.

Optional:
- `tools`: List allowed tools. Omit to allow all tools, or set `[]` for no tools.
- `disallowedTools`: Denylist to block specific tools.
- `model`: Model override if supported in your Claude Code setup.
- `permissionMode`: Permission handling mode for tool use.
- `skills`: Skill names to preload for this subagent.
- `hooks`: Hook list to run during execution.
- `disabled`: Set true to disable without deleting.
- `color`: Display color for terminal visibility (cyan, blue, green, magenta, yellow, red, white).

## Tools and Permissions
Permission modes:
- `default`: Ask for confirmation when required.
- `acceptEdits`: Auto-accept file edits but still ask for shell commands.
- `dontAsk`: Auto-deny tool use.
- `bypassPermissions`: Skip permission prompts (use only in trusted setups).
- `plan`: Always plan before tool use.

## Skills and Hooks
- `skills` preloads skill content for the subagent and is not inherited from the parent.
- `hooks` can automate setup steps but should be used sparingly and documented.

## System Prompt Note
Subagents only receive their own system prompt, not the full Claude Code system prompt. Include all required constraints in the subagent file.

## Delegation Patterns
- Use subagents for verbose or specialized tasks to keep the main context clean.
- Use the main agent for interactive, iterative work.
- Subagents cannot spawn other subagents; coordinate delegation from the main agent.
