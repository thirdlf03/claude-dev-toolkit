# Claude Dev Toolkit

Claude Code の開発生産性を向上させるプラグイン。リポジトリ分析、セッション管理、コードインスペクション、レビュー機能を提供します。

## インストール

```bash
# marketplace を追加
/plugin marketplace add thirdlf03/claude-dev-toolkit

# プラグインをインストール
/plugin install claude-dev-toolkit@thirdlf03-claude-dev-toolkit
```

## Skills

| Skill | 説明 | トリガー |
|-------|------|---------|
| **fast-onboard** | リポジトリ分析と CLAUDE.md 生成 | `/fast-onboard`, "analyze project" |
| **session-bridge** | セッション継続と前回の作業再開 | `/session-bridge`, "resume", "続き" |
| **claude-inspector** | .claude/ ディレクトリの包括的分析 | `/claude-inspector` |
| **skill-reviewer** | Skill の品質レビュー | `/skill-reviewer`, "review skill" |
| **agent-reviewer** | Subagent の品質レビュー | `/agent-reviewer`, "review agent" |
| **skill-pipeline** | リサーチから Skill 作成までの自動化 | `/skill-pipeline` |
| **claude-code-subagent-builder** | カスタムエージェント作成 | "create agent", "new subagent" |

## Agents

### 分析系

- **repo-analyzer** - CLAUDE.md 生成用リポジトリ分析
- **deep-researcher** - Web リサーチと JSON レポート生成
- **parallel-researcher** - 並列リサーチとレポート統合

### インスペクター系

- **inspector-hooks** - hooks 設定分析
- **inspector-memory** - CLAUDE.md 品質チェック
- **inspector-rules** - ルール設定分析
- **inspector-mcp** - MCP サーバー設定分析
- **inspector-settings** - settings.json 分析
- **inspector-classification** - skill/subagent 分類検証

### レビュー・検証系

- **skill-reviewer** - Skill 品質評価
- **agent-reviewer** - Subagent 品質評価
- **auto-validator** - コード自動検証と修正

## 使用例

### 新しいプロジェクトを分析

```
/fast-onboard
```

### 前回の作業を再開

```
/session-bridge
```

### .claude/ 設定を診断

```
/claude-inspector
```

### Skill の品質をレビュー

```
/skill-reviewer
```

## 依存関係

一部の skill は外部ツールを必要とします：

- `jq` - JSON 処理（fast-onboard で必須）
- `scc` - コード統計（推奨）
- `fd` - ファイル検索（推奨）
- `tree` - ディレクトリ構造（推奨）

## MCP サーバー連携

`session-bridge` skill は claude-mem MCP サーバーとの連携を想定しています。
MCP サーバーがない環境でも動作しますが、セッション継続機能が制限されます。

## ライセンス

MIT
