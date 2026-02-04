#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DURATION="${FAST_ONBOARD_CACHE_SECONDS:-3600}"  # 1時間

PROJECT_ROOT="${1:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
    if git rev-parse --show-toplevel > /dev/null 2>&1; then
        PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    else
        PROJECT_ROOT="."
    fi
fi
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

CACHE_DIR="$PROJECT_ROOT/.claude"
CACHE_FILE="$CACHE_DIR/.onboard-cache.json"

# キャッシュディレクトリ作成
mkdir -p "$CACHE_DIR"

# キャッシュチェック
if [[ "${FAST_ONBOARD_FORCE:-0}" != "1" && -f "$CACHE_FILE" ]]; then
    if [[ $(uname) == "Darwin" ]]; then
        CACHE_AGE=$(($(date +%s) - $(stat -f %m "$CACHE_FILE")))
    else
        CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    fi

    if [[ $CACHE_AGE -lt $CACHE_DURATION ]]; then
        echo "# ⚡ Using cache (${CACHE_AGE}s old)" >&2
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# 新規実行
echo "# 🔍 Fresh analysis with SCC..." >&2
bash "$SCRIPT_DIR/collect_data.sh" "$PROJECT_ROOT" | tee "$CACHE_FILE"
