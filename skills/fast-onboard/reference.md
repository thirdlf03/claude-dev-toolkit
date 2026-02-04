# Fast Onboard Reference

## Required Tools

| Tool | Status | Purpose |
|------|--------|---------|
| `jq` | **Required** | JSON generation and processing |
| `scc` | Recommended | Code statistics (lines, languages) |
| `fd` | Recommended | Fast file discovery |
| `tree` | Recommended | Directory structure visualization |
| `git` | Optional | Repository information |

Missing recommended tools result in `null` or empty values with warnings logged.

## repo-analyzer Prompt Template

Use this prompt when launching the repo-analyzer subagent:

```
Analyze this project using the collected JSON statistics and generate CLAUDE.md.

Data sources to use:
- JSON statistics above (SCC, file counts, Git info)
- README.md (full content if exists)
- Dependency files (package.json, requirements.txt, etc.)
- Infrastructure configs (docker-compose.yml, etc.)
- Key source files (sample up to 3 files from src/, max 80 lines each)

Generate CLAUDE.md and save it to the project root.
```

## JSON Structure

### Root Fields

| Field | Type | Description |
|-------|------|-------------|
| `meta` | object | Generation metadata and tool availability |
| `project` | object | Basic project information |
| `git` | object \| null | Git repository information |
| `codeStats` | object \| null | SCC statistics by file |
| `files` | object | File counts by language |
| `dependencyFiles` | array | Paths to dependency files |
| `docs` | array | Paths to documentation files |
| `infrastructure` | array | Paths to infrastructure configs |
| `structure` | array | Directory tree (from `tree -J`) |
| `warnings` | array | Collection warnings |

### Field Details

#### `meta`

```json
{
  "generatedAt": "2026-02-04T03:20:00Z",
  "tools": {
    "scc": true,
    "fd": true,
    "tree": true,
    "jq": true
  }
}
```

#### `project`

```json
{
  "name": "my-project",
  "path": "/absolute/path/to/my-project"
}
```

#### `git`

```json
{
  "remote": "https://github.com/user/repo.git",
  "branch": "main",
  "lastCommit": "abc1234 - Fix bug in parser"
}
```

Returns `null` if not a Git repository.

#### `files`

```json
{
  "total": 42,
  "javascript": 15,
  "python": 10,
  "go": 0,
  "rust": 0
}
```

All values are `null` if `fd` is unavailable.

## Cache Management

### Cache Location

```
.claude/.onboard-cache.json
```

**Recommendation**: Add `.claude/` to `.gitignore` to avoid committing cache files.

### Cache Behavior

| Scenario | Action |
|----------|--------|
| Cache exists and fresh | Return cached JSON |
| Cache expired (>3600s) | Regenerate and update cache |
| `FAST_ONBOARD_FORCE=1` | Always regenerate |
| Cache missing | Generate and create cache |

### Clearing Cache

```bash
# Method 1: Delete cache file
rm .claude/.onboard-cache.json

# Method 2: Force regeneration
FAST_ONBOARD_FORCE=1 bash .claude/skills/fast-onboard/scripts/cached_collect.sh
```

### Custom TTL

```bash
# Set cache TTL to 30 minutes (1800 seconds)
FAST_ONBOARD_CACHE_SECONDS=1800 bash .claude/skills/fast-onboard/scripts/cached_collect.sh
```

## Complete JSON Example

```json
{
  "meta": {
    "generatedAt": "2026-02-04T03:20:00Z",
    "tools": {
      "scc": true,
      "fd": true,
      "tree": true,
      "jq": true
    }
  },
  "project": {
    "name": "test-fast-init",
    "path": "/Users/naoki/github/test-fast-init"
  },
  "git": {
    "remote": "none",
    "branch": "main",
    "lastCommit": "abc1234 - Initial commit"
  },
  "codeStats": [
    {
      "Name": "TypeScript",
      "Files": 7,
      "Lines": 161,
      "Code": 140,
      "Comments": 5,
      "Blanks": 16
    }
  ],
  "files": {
    "total": 16,
    "javascript": 7,
    "python": 0,
    "go": 0,
    "rust": 0
  },
  "dependencyFiles": [
    "package.json",
    "package-lock.json"
  ],
  "docs": [
    "README.md",
    "CLAUDE.md"
  ],
  "infrastructure": [
    ".github/workflows/ci.yml"
  ],
  "structure": [
    {
      "type": "directory",
      "name": ".",
      "contents": [
        {"type": "directory", "name": "src"},
        {"type": "directory", "name": "tests"},
        {"type": "directory", "name": "public"}
      ]
    }
  ],
  "warnings": []
}
```

## Search Depth Constants

The collection script uses these search depths (configurable in script):

| Constant | Value | Purpose |
|----------|-------|---------|
| Dependency files | `-d 3` | Deps rarely nested deeper than 3 levels |
| Documentation | `-d 2` | Docs typically at root or one level deep |
| Infrastructure | `-d 3` | Config files near root |
| GitHub workflows | `-d 4` | `.github/workflows/` is 3 levels deep |
| Tree structure | `-L 2` | Overview without excessive detail |

## Excluded Directories

The following directories are excluded from all searches:

```
node_modules, dist, build, target, .git, vendor, venv,
__pycache__, .next, coverage, .claude
```
