#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Fast Onboard - Project Data Collection Script
# =============================================================================
# Collects repository metadata, code statistics, and file inventories for
# generating CLAUDE.md documentation.
#
# Required: jq
# Optional: scc, fd, tree, git
# =============================================================================

# --- Configuration Constants -------------------------------------------------
# Search depth limits (balance between coverage and performance):
#   DEPTH_DEPS=3      - Dependency files rarely nested deeper than 3 levels
#   DEPTH_DOCS=2      - Documentation typically at root or one level deep
#   DEPTH_INFRA=3     - Infrastructure configs near root
#   DEPTH_WORKFLOWS=4 - .github/workflows/ is 3 levels deep
#   TREE_DEPTH=2      - Directory structure overview without excessive detail
#
# Excluded directories (build artifacts, dependencies, caches):
#   node_modules, dist, build, target, .git, vendor, venv,
#   __pycache__, .next, coverage, .claude
# -----------------------------------------------------------------------------

PROJECT_ROOT="${1:-.}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
cd "$PROJECT_ROOT"

warnings=()

has_scc=false
has_fd=false
has_tree=false
has_jq=false

if command -v jq >/dev/null 2>&1; then
  has_jq=true
else
  echo "jq not found: JSON generation requires jq." >&2
  exit 1
fi

if command -v scc >/dev/null 2>&1; then
  has_scc=true
else
  warnings+=("scc not found: codeStats is null")
fi

if command -v fd >/dev/null 2>&1; then
  has_fd=true
else
  warnings+=("fd not found: file stats and file lists are empty")
fi

if command -v tree >/dev/null 2>&1; then
  has_tree=true
else
  warnings+=("tree not found: structure is empty")
fi

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
project_name="$(basename "$PROJECT_ROOT")"
project_path="$PROJECT_ROOT"

git_json="null"
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_remote="$(git remote get-url origin 2>/dev/null || echo 'none')"
  git_branch="$(git branch --show-current 2>/dev/null || echo 'main')"
  git_last_commit="$(git log -1 --format='%h - %s' 2>/dev/null || echo 'none')"
  git_json="$(jq -n --arg remote "$git_remote" --arg branch "$git_branch" --arg lastCommit "$git_last_commit" '{remote:$remote,branch:$branch,lastCommit:$lastCommit}')"
fi

code_stats_json="null"
if [[ "$has_scc" == "true" ]]; then
  code_stats_json="$(scc --format json --by-file \
    --exclude-dir node_modules,dist,build,target,.git,vendor,venv,__pycache__,.next,coverage,.claude \
    --no-cocomo \
    --no-size \
    . 2>/dev/null | jq -c '.' || echo 'null')"
fi

total_files="null"
js_files="null"
py_files="null"
go_files="null"
rust_files="null"

deps_json="[]"
docs_json="[]"
infra_json="[]"
structure_json="[]"

if [[ "$has_fd" == "true" ]]; then
  # File counts by language
  total_files="$(fd -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude . 2>/dev/null | wc -l | tr -d ' ')"
  js_files="$(fd -e js -e jsx -e ts -e tsx -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude 2>/dev/null | wc -l | tr -d ' ')"
  py_files="$(fd -e py -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude 2>/dev/null | wc -l | tr -d ' ')"
  go_files="$(fd -e go -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude 2>/dev/null | wc -l | tr -d ' ')"
  rust_files="$(fd -e rs -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude 2>/dev/null | wc -l | tr -d ' ')"

  # Dependency files (depth 3: rarely nested deeper)
  deps_json="$(fd -d 3 -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude \
    'package\.json$|requirements\.txt$|go\.mod$|Cargo\.toml$|Gemfile$|pom\.xml$|build\.gradle$|pyproject\.toml$|yarn\.lock$|package-lock\.json$|pnpm-lock\.yaml$|bun\.lockb$|poetry\.lock$|Pipfile$|uv\.lock$' \
    . 2>/dev/null | jq -R . | jq -s .)"

  # Documentation files (depth 2: typically at root level)
  docs_json="$(fd -d 2 -t f -i -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude \
    'readme|contributing|changelog|license|architecture|todo' \
    . 2>/dev/null | jq -R . | jq -s .)"

  # Infrastructure and config files (depth 3 for root, depth 4 for workflows)
  infra_files="$(
    {
      fd -d 3 -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude \
        'Dockerfile|docker-compose\.yml|\.gitlab-ci\.yml|Jenkinsfile|Makefile|\.env\.example' \
        .
      # GitHub workflows at .github/workflows/ (3 levels deep, need depth 4)
      fd -d 4 -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude \
        -g '.github/workflows/*.yml' .
      fd -d 4 -t f -E node_modules -E dist -E build -E target -E .git -E vendor -E venv -E __pycache__ -E .next -E coverage -E .claude \
        -g '.github/workflows/*.yaml' .
    } 2>/dev/null | sort -u
  )"

  if [[ -n "$infra_files" ]]; then
    infra_json="$(printf '%s\n' "$infra_files" | jq -R . | jq -s .)"
  else
    infra_json="[]"
  fi
fi

if [[ "$has_tree" == "true" ]]; then
  # Directory structure overview (depth 2: avoid excessive detail)
  structure_json="$(tree -L 2 -d -J -I 'node_modules|dist|build|target|.git|vendor|venv|__pycache__|.next|coverage|.claude' . 2>/dev/null | jq -c '.' || echo '[]')"
fi

warnings_json="[]"
if [[ ${#warnings[@]} -gt 0 ]]; then
  warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
fi

jq -n \
  --arg generatedAt "$generated_at" \
  --arg name "$project_name" \
  --arg path "$project_path" \
  --argjson git "$git_json" \
  --argjson codeStats "$code_stats_json" \
  --argjson total "$total_files" \
  --argjson javascript "$js_files" \
  --argjson python "$py_files" \
  --argjson go "$go_files" \
  --argjson rust "$rust_files" \
  --argjson dependencyFiles "$deps_json" \
  --argjson docs "$docs_json" \
  --argjson infrastructure "$infra_json" \
  --argjson structure "$structure_json" \
  --argjson warnings "$warnings_json" \
  --argjson hasScc "$has_scc" \
  --argjson hasFd "$has_fd" \
  --argjson hasTree "$has_tree" \
  --argjson hasJq "$has_jq" \
  '{
    meta: {
      generatedAt: $generatedAt,
      tools: {
        scc: $hasScc,
        fd: $hasFd,
        tree: $hasTree,
        jq: $hasJq
      }
    },
    project: {
      name: $name,
      path: $path
    },
    git: $git,
    codeStats: $codeStats,
    files: {
      total: $total,
      javascript: $javascript,
      python: $python,
      go: $go,
      rust: $rust
    },
    dependencyFiles: $dependencyFiles,
    docs: $docs,
    infrastructure: $infrastructure,
    structure: $structure,
    warnings: $warnings
  }'
