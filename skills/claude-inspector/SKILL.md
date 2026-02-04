---
name: claude-inspector
description: Comprehensive .claude/ directory inspector. Orchestrates multiple specialized subagents to analyze settings, hooks, memory, MCP, rules, and skills/subagents classification. Provides prioritized recommendations with examples and rationale.
allowed-tools:
  - Task
  - Read
  - Glob
---

# Claude Inspector

`.claude/`ディレクトリの包括的な検査を実行し、最適化推奨事項を提供します。

## Usage

```
/claude-inspector
```

Or naturally: "inspect my .claude config", "check Claude Code setup", "audit settings"

## Prerequisites

**Required subagents** (`.claude/agents/`):
- `inspector-settings.md`
- `inspector-hooks.md`
- `inspector-memory.md`
- `inspector-mcp.md`
- `inspector-rules.md`
- `inspector-classification.md`

**Error if missing**: Report which subagent is unavailable and provide template to create it.

## Critical: 並列実行

**必ず6つのsubagentを単一のメッセージで並列起動してください。**

```
// 単一メッセージで6つのTask toolを同時呼び出し
Task(subagent_type: "inspector-settings", prompt: "...")
Task(subagent_type: "inspector-hooks", prompt: "...")
Task(subagent_type: "inspector-memory", prompt: "...")
Task(subagent_type: "inspector-mcp", prompt: "...")
Task(subagent_type: "inspector-rules", prompt: "...")
Task(subagent_type: "inspector-classification", prompt: "...")
```

## ワークフロー

### Phase 1: プロジェクト情報収集

```
Use Glob to detect project type:
- package.json → Node.js
- requirements.txt/pyproject.toml → Python
- go.mod → Go
- Cargo.toml → Rust
```

### Phase 2: 並列検査実行

| Subagent | 担当領域 |
|----------|----------|
| inspector-settings | settings.json最適化 |
| inspector-hooks | hooks推奨と自動化 |
| inspector-memory | CLAUDE.md品質チェック |
| inspector-mcp | MCP設定検証 |
| inspector-rules | Rulesディレクトリ活用 |
| inspector-classification | Skills/Subagents分類検証 |

### Phase 3: 結果統合

各subagentからのJSON出力を統合し、優先度順にソート。

### Phase 4: レポート生成

**出力形式**: JSON（スキーマは [output-schema.json](references/output-schema.json) を参照）

## 優先度システム

| Priority | 基準 | 例 |
|----------|------|-----|
| Critical | セキュリティリスク、データ損失 | .envが未制限 |
| High | 効率に大影響、ベストプラクティス違反 | permissions未設定 |
| Medium | 便利機能、最適化 | hooks未活用 |
| Low | 軽微な改善 | color未設定 |

## 検査カテゴリ

| カテゴリ | 検査内容 |
|----------|----------|
| Settings | 基本設定、セキュリティ、settings.local.json分離 |
| Hooks | 既存hooks分析、セキュリティ、推奨hooks |
| Memory | CLAUDE.md存在・品質・構造、.gitignore連携 |
| MCP | .mcp.json検証、セキュリティ、推奨サーバー |
| Rules | ディレクトリ活用、既存分析、推奨Rules |
| Classification | Skills/Subagents分類、Frontmatter検証、誤分類検出 |

## Quick Wins

すぐに実装できて効果の高い改善を抽出：
- 実装時間: 2-5分
- 影響度: High以上
- 具体的な手順付き

## プロジェクトタイプ別対応

| タイプ | カスタマイズ |
|--------|-------------|
| Node.js/TypeScript | npm hooks, ESLint連携, Node.js MCP |
| Python | 仮想環境チェック, pip hooks, Python MCP |
| Git連携 | Git hooks, GitHub MCP, Commit規約Rules |

## 制約事項

- **Read-only**: 設定ファイルを変更しない（検査のみ）
- **並列実行必須**: 6つのsubagentを同時起動
- **JSON出力**: 構造化されたレポート

## Error Handling

| Issue | Solution |
|-------|----------|
| subagentファイル未検出 | `ls .claude/agents/inspector-*.md` で確認 |
| 検査時間が長い | 大規模プロジェクトの場合は正常 |
| 結果統合エラー | 各subagentの出力を個別確認 |

## References

- [output-schema.json](references/output-schema.json) - 出力JSONスキーマ
- [classification-criteria.md](references/classification-criteria.md) - 分類基準詳細
- [official-guidelines.md](references/official-guidelines.md) - 公式ガイドライン要約
