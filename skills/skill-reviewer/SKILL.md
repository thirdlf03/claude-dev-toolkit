---
name: skill-reviewer
description: Claude Code Skillsのレビューと品質改善。ベストプラクティスに基づいてSkillを分析し、評価レポートと改善提案を提供。"review skill", "skillをレビュー", "skill品質チェック" で起動。
allowed-tools:
  - Task
  - Read
  - Glob
model: haiku
---

# Skill Reviewer

Skillの品質レビューと改善提案を行います。

## Prerequisites

**Required subagent**:
- `.claude/agents/skill-reviewer.md` - Skillレビューを実行

## Usage

```
/skill-reviewer [skill-name or path]
```

例:
- `/skill-reviewer fast-onboard`
- `/skill-reviewer .claude/skills/session-bridge/SKILL.md`
- `/skill-reviewer --all`

## Workflow

### 1. 対象Skillの特定

**引数あり**: 指定されたスキルをレビュー
```
/skill-reviewer fast-onboard
→ .claude/skills/fast-onboard/SKILL.md をレビュー
```

**引数なし**: 対話的に選択
```
/skill-reviewer
→ 利用可能なスキル一覧を表示:
   1. fast-onboard
   2. session-bridge
   3. claude-inspector
   ...
→ ユーザーに選択を求める
```

**--all オプション**: 全スキルをレビュー
```
/skill-reviewer --all
→ .claude/skills/*/SKILL.md を全て並列レビュー
```

### 2. skill-reviewer subagent を起動

```
Task(
  subagent_type: "skill-reviewer",
  prompt: "[skill-path] のSkillをレビューしてください。評価レポートと改善提案を出力してください。"
)
```

### 3. 結果をユーザーに提示

## Options

| Option | Description | Status |
|--------|-------------|--------|
| `--fix` | 自動修正を適用 | 実装済み |
| `--all` | 全Skillをレビュー | 実装済み |
| `--score-only` | スコアのみ表示 | 実装済み |

## Error Handling

| Condition | Behavior |
|-----------|----------|
| Skill not found | エラーメッセージ + 利用可能なスキル一覧を表示 |
| subagent missing | エラー報告 + subagent作成を提案 |
| SKILL.md parse error | YAMLエラー箇所を特定して報告 |
| --all で一部失敗 | 成功したものは結果表示、失敗したものはエラー報告 |

## Output Format

```
📋 Skill Review: [skill-name]

✅ 良い点
- ...

⚠️ 改善提案
1. [問題] → [解決策]

📊 適合度スコア: ⭐⭐⭐⭐☆ (4/5)

🎯 推奨アクション
1. [優先度高] ...
2. [優先度中] ...
```
