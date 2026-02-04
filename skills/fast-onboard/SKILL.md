---
name: fast-onboard
description: Analyzes repository structure and generates CLAUDE.md documentation. Use when user mentions "onboard", "analyze project", "understand codebase", "project structure", or when working with new/unfamiliar repositories.
allowed-tools:
  - Bash
  - Read
  - Write
  - Task
  - Glob
model: haiku
---

# Fast Onboard

Rapidly analyzes new projects and generates comprehensive CLAUDE.md documentation.

## Prerequisites

**Required**: `jq` (Fatal if missing)
**Recommended**: `scc`, `fd`, `tree`
**Subagent**: `.claude/agents/repo-analyzer.md`

## Workflow

### Step 1: Parallel Data Collection

Execute these Bash commands **in parallel** (single message with multiple Bash tool calls):

| # | Command | Output |
|---|---------|--------|
| 1 | `command -v jq && echo ok` | jq check (abort if missing) |
| 2 | `scc --format json --by-file --no-cocomo --no-size --exclude-dir node_modules,dist,build,target,.git,vendor,venv,__pycache__,.next,coverage,.claude . 2>/dev/null \|\| echo null` | Code stats |
| 3 | `git rev-parse --git-dir >/dev/null 2>&1 && jq -n --arg r "$(git remote get-url origin 2>/dev/null \|\| echo none)" --arg b "$(git branch --show-current)" --arg c "$(git log -1 --format='%h - %s' 2>/dev/null)" '{remote:$r,branch:$b,lastCommit:$c}' \|\| echo null` | Git info |
| 4 | `fd -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude . 2>/dev/null \| wc -l \| tr -d ' '` | Total files |
| 5 | `fd -e js -e jsx -e ts -e tsx -t f -E node_modules -E dist -E build -E .git -E .next -E coverage -E .claude 2>/dev/null \| wc -l \| tr -d ' '` | JS/TS files |
| 6 | `fd -e py -t f -E node_modules -E .git -E venv -E __pycache__ -E .claude 2>/dev/null \| wc -l \| tr -d ' '` | Python files |
| 7 | `fd -e go -t f -E node_modules -E .git -E vendor -E .claude 2>/dev/null \| wc -l \| tr -d ' '` | Go files |
| 8 | `fd -e rs -t f -E node_modules -E target -E .git -E .claude 2>/dev/null \| wc -l \| tr -d ' '` | Rust files |
| 9 | `fd -d 3 -t f -E node_modules -E .git -E .claude 'package\.json$\|requirements\.txt$\|go\.mod$\|Cargo\.toml$\|pyproject\.toml$' . 2>/dev/null \| jq -R . \| jq -sc .` | Deps |
| 10 | `fd -d 2 -t f -i -E node_modules -E .git -E .claude 'readme\|changelog\|license' . 2>/dev/null \| jq -R . \| jq -sc .` | Docs |
| 11 | `{ fd -d 3 -t f -E node_modules -E .git 'Dockerfile\|docker-compose\|Makefile' .; fd -d 4 -t f -g '.github/workflows/*.yml' .; } 2>/dev/null \| sort -u \| jq -R . \| jq -sc .` | Infra |
| 12 | `tree -L 2 -d -J -I 'node_modules\|dist\|build\|target\|.git\|vendor\|venv\|__pycache__\|.next\|coverage\|.claude' . 2>/dev/null \|\| echo '[]'` | Structure |

### Step 2: Assemble JSON

Combine results into `.claude/.onboard-cache.json`:

```bash
mkdir -p .claude && jq -n \
  --arg name "$(basename "$PWD")" \
  --arg path "$PWD" \
  --argjson git '<result_3>' \
  --argjson codeStats '<result_2>' \
  --argjson total <result_4> \
  --argjson js <result_5> \
  --argjson py <result_6> \
  --argjson go <result_7> \
  --argjson rust <result_8> \
  --argjson deps '<result_9>' \
  --argjson docs '<result_10>' \
  --argjson infra '<result_11>' \
  --argjson structure '<result_12>' \
  '{
    meta: {generatedAt: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))},
    project: {name: $name, path: $path},
    git: $git,
    codeStats: $codeStats,
    files: {total: $total, javascript: $js, python: $py, go: $go, rust: $rust},
    dependencyFiles: $deps,
    docs: $docs,
    infrastructure: $infra,
    structure: $structure
  }' > .claude/.onboard-cache.json
```

### Step 3: Launch repo-analyzer

```
Task(
  subagent_type: "repo-analyzer",
  prompt: "Analyze .claude/.onboard-cache.json and generate CLAUDE.md"
)
```

## Error Handling

| Condition | Behavior |
|-----------|----------|
| `jq` missing | **Fatal** - Abort workflow |
| `scc`/`fd`/`tree` missing | Use `null`/`0`/`[]`, continue |
| repo-analyzer missing | Report error |

## References

- [reference.md](./reference.md) - JSON schema, prompt template
