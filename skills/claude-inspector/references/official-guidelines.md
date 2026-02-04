# Claude Code 公式ガイドライン要約

2026年2月4日の調査に基づく公式ドキュメントの要約。

## ディレクトリ構造

### プロジェクトレベル（`.claude/`）

```
.claude/
├── settings.json              # プロジェクト設定（コミット推奨）
├── settings.local.json        # 個人設定（.gitignore推奨）
├── CLAUDE.md                  # プロジェクトメモリ
├── CLAUDE.local.md            # 個人メモリ（.gitignore推奨）
├── .mcp.json                  # MCP server設定
├── agents/                    # Subagent定義（*.md）
│   └── agent-name.md
├── skills/                    # Skill定義
│   └── skill-name/
│       ├── SKILL.md           # 必須
│       ├── scripts/           # オプション（実行スクリプト）
│       ├── references/        # オプション（参照ドキュメント）
│       └── assets/            # オプション（テンプレート、画像等）
├── rules/                     # ルール定義（*.md）
└── hooks/                     # Hookスクリプト（settings.jsonから参照）
```

### ユーザーレベル（`~/.claude/`）

```
~/.claude/
├── settings.json              # ユーザーグローバル設定
├── settings.local.json        # 個人設定
├── CLAUDE.md                  # ユーザーグローバルメモリ
├── agents/                    # ユーザーレベルsubagents
├── skills/                    # ユーザーレベルskills
├── plans/                     # プランファイル（設定可能）
└── plugins/                   # インストール済みプラグイン
```

## 設定の優先順位

### Settings

1. **Managed settings**（最高優先、上書き不可）
2. CLI引数
3. `.claude/settings.local.json`（プロジェクトローカル）
4. `.claude/settings.json`（プロジェクト）
5. `~/.claude/settings.json`（ユーザー）

### Skills

1. **Enterprise**（エンタープライズ）
2. Personal（`~/.claude/skills/`）
3. Project（`.claude/skills/`）
4. Plugin（`plugin/skills/`）

### Subagents

1. CLI `--agents`フラグ
2. Project（`.claude/agents/`）
3. User（`~/.claude/agents/`）
4. Plugin（`plugin/agents/`）

### Hooks

1. **Managed**（エンタープライズポリシー）
2. `settings.json`ファイル
3. Plugin（`hooks/hooks.json`）
4. Skill/Agent frontmatter（スコープ化）

## Skills 仕様

### 必須ファイル

- `SKILL.md`: YAML frontmatter + Markdown本文

### Frontmatter フィールド

**必須**:
- `name`: スキル名
- `description`: 使用条件とトリガー（自動起動の判断材料）

**オプション**:
- `allowed-tools`: 許可ツールリスト
- `argument-hint`: 引数ヒント
- `disable-model-invocation`: `true`で自動起動無効化（手動のみ）
- `user-invocable`: `false`でメニュー非表示
- `model`: `sonnet`/`opus`/`haiku`
- `context`: `fork`で独立コンテキスト実行
- `agent`: 実行するsubagent名
- `hooks`: Hook設定

### ベストプラクティス

- ✅ SKILL.md本文は**500行以内**を推奨
- ✅ 詳細は`references/`に分割
- ✅ スクリプトは`scripts/`に配置（トークン効率的）
- ✅ テンプレートは`assets/`に配置
- ❌ README.md等の補助ドキュメント不要（AI専用）

### 進歩的な開示パターン

```
skill-name/
├── SKILL.md                   # コア（<500行）
└── references/
    ├── api-reference.md       # 必要時のみ読込
    ├── examples.md            # 必要時のみ読込
    └── advanced.md            # 必要時のみ読込
```

## Subagents 仕様

### ファイル形式

- 単一のMarkdownファイル: `agent-name.md`
- YAML frontmatter + システムプロンプト本文

### Frontmatter フィールド

**必須**:
- `name`: エージェント名（lowercase-with-hyphens）
- `description`: 委譲条件の説明

**オプション**:
- `tools`: 許可ツールリスト（省略=全て、`[]`=無し）
- `disallowedTools`: 禁止ツールリスト
- `model`: `sonnet`/`opus`/`haiku`/`inherit`（デフォルト: inherit）
- `permissionMode`: `default`/`acceptEdits`/`dontAsk`/`bypassPermissions`/`plan`
- `skills`: プリロードするskillリスト
- `hooks`: Hook設定
- `color`: 表示色（cyan/magenta/green等）

### ベストプラクティス

- ✅ 1つのsubagentに1つの焦点タスク
- ✅ ツールを最小限に制限（セキュリティ）
- ✅ 読み取り専用探索にはread-onlyツール
- ✅ 大量出力はsubagentで独立コンテキスト
- ❌ Subagentから別のsubagentをspawnできない

### ビルトインSubagents

- `Explore`: 読み取り専用（Haiku、高速）
- `Plan`: プランモード専用
- `general-purpose`: フルツールアクセス
- `Bash`: コマンド実行専門
- `statusline-setup`: ステータスライン設定
- `claude-code-guide`: ドキュメント参照

## Hooks

### イベント一覧

**ライフサイクル**:
- `SessionStart`: セッション開始時
- `SessionEnd`: セッション終了時

**ユーザー対話**:
- `UserPromptSubmit`: ユーザー送信時

**ツール実行**:
- `PreToolUse`: ツール実行前
- `PermissionRequest`: パーミッション要求時
- `PostToolUse`: ツール実行後
- `PostToolUseFailure`: ツール実行失敗時

**エージェント**:
- `SubagentStart`: Subagent開始時
- `SubagentStop`: Subagent終了時
- `Stop`: 停止要求時

**その他**:
- `Notification`: 通知時
- `PreCompact`: 自動コンパクト前

### Hook種別

- `command`: シェルスクリプト実行
- `prompt`: LLM評価
- `agent`: Subagent実行（ツール使用可能）

### 終了コード

- `0`: 成功（JSON出力をパース）
- `2`: ブロッキングエラー（stderrをClaudeに表示）
- その他: 非ブロッキングエラー

### 環境変数

- `$CLAUDE_PROJECT_DIR`: プロジェクトルート
- `${CLAUDE_PLUGIN_ROOT}`: プラグインルート
- `CLAUDE_ENV_FILE`: 環境変数永続化（SessionStartのみ）

## Permissions

### パーミッションルール

```json
{
  "allow": ["Bash(npm run *)", "Read(./config/*.json)"],
  "ask": ["Write(**/*.ts)"],
  "deny": ["Read(./.env)", "Bash(rm -rf *)"]
}
```

### ツール指定パターン

- `Bash(pattern)`: コマンドパターン
- `Read(pattern)`: ファイルパス（glob）
- `Write(pattern)`: ファイルパス（glob）
- `Edit(pattern)`: ファイルパス（glob）
- `WebFetch(domain:example.com)`: ドメイン
- `Task(subagent-name)`: Subagent名

### Sandbox

```json
{
  "sandbox": {
    "enabled": true,
    "network": {
      "allowedDomains": ["*.example.com"]
    },
    "excludedCommands": ["rm", "dd"]
  }
}
```

## MCP (Model Context Protocol)

### プロジェクトレベル

```json
// .mcp.json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "my-mcp-server"]
    }
  }
}
```

### ユーザーレベル

```json
// ~/.claude.json
{
  "mcpServers": { ... },
  "preferences": { ... }
}
```

### Settings制御

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["server1"],
  "disabledMcpjsonServers": ["server2"],
  "allowedMcpServers": ["server1", "server2"],
  "deniedMcpServers": ["dangerous-server"]
}
```

## Plugins

### プラグイン構造

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json            # メタデータ
├── skills/
│   └── skill-name/
│       └── SKILL.md
├── agents/
│   └── agent-name.md
├── commands/
│   └── command-name.md
├── hooks/
│   └── hooks.json
└── .mcp.json                  # オプション
```

### plugin.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin description",
  "author": "Author Name",
  "repository": "https://github.com/user/repo"
}
```

### Settings制御

```json
{
  "enabledPlugins": {
    "plugin-name@marketplace": true
  },
  "extraKnownMarketplaces": {
    "my-marketplace": "https://example.com/marketplace.json"
  }
}
```

## Memory (CLAUDE.md)

### 階層構造

1. `~/.claude/CLAUDE.md`（ユーザーグローバル）
2. `./CLAUDE.md`（プロジェクトルート）
3. サブディレクトリの`CLAUDE.md`（再帰的）
4. `*.local.md`ファイル（個人用、.gitignore）

### Import構文

```markdown
# CLAUDE.md

@path/to/other-file.md

プロジェクト特有の情報...
```

### ベストプラクティス

- ✅ プロジェクト共通情報はコミット
- ✅ 個人設定は`.local.md`に分離
- ✅ 階層構造を活用（ルート → サブディレクトリ）

## 設定ファイル例

### settings.json

```json
{
  "model": "sonnet",
  "language": "ja",
  "outputStyle": "concise",
  "respectGitignore": true,
  "plansDirectory": "~/.claude/plans/",
  "env": {
    "MY_VAR": "value"
  },
  "hooks": {
    "SessionStart": {
      "type": "command",
      "command": "bash .claude/hooks/session-start.sh"
    }
  },
  "allow": [],
  "ask": [],
  "deny": []
}
```

## 公式ドキュメントリンク

- **Settings**: https://code.claude.com/docs/en/settings
- **Skills**: https://code.claude.com/docs/en/skills
- **Subagents**: https://code.claude.com/docs/en/sub-agents
- **Hooks**: https://code.claude.com/docs/en/hooks
- **Permissions**: https://code.claude.com/docs/en/permissions
- **Memory**: https://code.claude.com/docs/en/memory
- **Plugins**: https://code.claude.com/docs/en/plugins
- **MCP**: https://code.claude.com/docs/en/mcp
- **Best Practices**: https://www.anthropic.com/engineering/claude-code-best-practices

## JSON Schema

- Settings: https://json.schemastore.org/claude-code-settings.json
