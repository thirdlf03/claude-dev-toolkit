#!/bin/bash
#
# collect_context.sh - Collect project context for session bridging
#
# Usage: bash .claude/skills/session-bridge/scripts/collect_context.sh [project_path]
#
# Outputs JSON with:
# - Project name and type detection
# - VCS status (git/jj)
# - Suggested memory search queries
#
# Exit codes:
#   0 - Success
#   1 - General error
#

set -euo pipefail

# Default to current directory
PROJECT_PATH="${1:-.}"
cd "$PROJECT_PATH"
PROJECT_ROOT="$(pwd)"

# Detect project name
detect_project_name() {
    # Try package.json
    if [[ -f "package.json" ]]; then
        name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
        if [[ -n "$name" ]]; then
            echo "$name"
            return
        fi
    fi

    # Try go.mod
    if [[ -f "go.mod" ]]; then
        name=$(head -1 go.mod | sed 's/module //' | xargs basename 2>/dev/null)
        if [[ -n "$name" ]]; then
            echo "$name"
            return
        fi
    fi

    # Try Cargo.toml
    if [[ -f "Cargo.toml" ]]; then
        name=$(grep -o '^name[[:space:]]*=[[:space:]]*"[^"]*"' Cargo.toml 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
        if [[ -n "$name" ]]; then
            echo "$name"
            return
        fi
    fi

    # Try pyproject.toml
    if [[ -f "pyproject.toml" ]]; then
        name=$(grep -o '^name[[:space:]]*=[[:space:]]*"[^"]*"' pyproject.toml 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
        if [[ -n "$name" ]]; then
            echo "$name"
            return
        fi
    fi

    # Fallback to directory name
    basename "$PROJECT_ROOT"
}

# Detect project type
detect_project_type() {
    if [[ -f "next.config.js" ]] || [[ -f "next.config.mjs" ]] || [[ -f "next.config.ts" ]]; then
        echo "nextjs"
    elif [[ -f "vite.config.ts" ]] || [[ -f "vite.config.js" ]]; then
        echo "vite"
    elif [[ -f "package.json" ]]; then
        echo "nodejs"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        echo "python"
    elif [[ -f "Gemfile" ]]; then
        echo "ruby"
    else
        echo "unknown"
    fi
}

# Get VCS status
get_vcs_status() {
    local vcs_type="none"
    local branch=""
    local uncommitted=0
    local has_stash="false"

    # Check for jj first (preferred) - but only if jj command exists
    if [[ -d ".jj" ]] && command -v jj >/dev/null 2>&1; then
        vcs_type="jj"
        # Get current change description or bookmark
        branch=$(jj log -r @ --no-graph -T 'if(bookmarks, bookmarks, change_id.short())' 2>/dev/null || echo "unknown")
        # Count modified files
        uncommitted=$(jj status 2>/dev/null | grep -c "^[MAD]" || echo "0")
    # Then check for git
    elif [[ -d ".git" ]] || git rev-parse --git-dir >/dev/null 2>&1; then
        vcs_type="git"
        branch=$(git branch --show-current 2>/dev/null || echo "detached")
        uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if git stash list 2>/dev/null | grep -q .; then
            has_stash="true"
        fi
    fi

    echo "{\"type\":\"$vcs_type\",\"branch\":\"$branch\",\"uncommitted_changes\":$uncommitted,\"has_stash\":$has_stash}"
}

# Calculate date 7 days ago in ISO8601
get_date_7_days_ago() {
    if date --version >/dev/null 2>&1; then
        # GNU date
        date -d "7 days ago" -u +"%Y-%m-%dT00:00:00Z"
    else
        # BSD date (macOS)
        date -v-7d -u +"%Y-%m-%dT00:00:00Z"
    fi
}

# Main execution
PROJECT_NAME=$(detect_project_name)
PROJECT_TYPE=$(detect_project_type)
VCS_STATUS=$(get_vcs_status)
DATE_START=$(get_date_7_days_ago)

# Build suggested queries
QUERIES="[
    \"incomplete task $PROJECT_NAME\",
    \"session-request $PROJECT_NAME\",
    \"bugfix $PROJECT_NAME\",
    \"decision $PROJECT_NAME\",
    \"feature $PROJECT_NAME\"
  ]"

# Output JSON
cat <<EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "root": "$PROJECT_ROOT",
    "type": "$PROJECT_TYPE"
  },
  "vcs": $VCS_STATUS,
  "memory_query": {
    "dateStart": "$DATE_START",
    "suggested_queries": $QUERIES
  }
}
EOF
