# Skills vs Subagents 分類基準

公式ガイドライン（2026年2月時点）に基づく詳細な分類基準。

## 基本原則

**Skills**: Claudeの能力をインラインで拡張する知識とパターン
**Subagents**: 独立したコンテキストで実行される専門AI

## 判定フローチャート

```
タスクは複数の決定点を含むワークフローか？
├─ YES → Subagent
└─ NO
    ├─ 大量の出力を生成するか？
    │   ├─ YES → Subagent
    │   └─ NO
    │       ├─ 並列・独立した調査が必要か？
    │       │   ├─ YES → Subagent
    │       │   └─ NO
    │       │       ├─ 厳密なツール制限が必要か？
    │       │       │   ├─ YES → Subagent
    │       │       │   └─ NO → Skill
```

## 詳細な分類基準

### Skills の特徴

#### 1. 単一の明確なタスク

**良い例（Skill）**:
- PDFを回転させる
- 画像をリサイズする
- データベーススキーマを参照する
- 特定のファイル形式に変換する

**悪い例（Subagentにすべき）**:
- ウェブサイト全体を構築する（複数ステップ）
- バグを調査して修正する（決定点あり）
- リポジトリを分析してドキュメント生成（複雑なワークフロー）

#### 2. ポータブルな専門知識

**良い例（Skill）**:
- コーディングスタイルガイド
- API仕様書
- データベーススキーマ定義
- ブランドガイドライン
- 会社のポリシー

**特徴**:
- 主にマークダウンのドキュメント
- ツール使用は最小限（ReadやBash程度）
- プロジェクト間で再利用可能

#### 3. 高速実行が必要

**良い例（Skill）**:
- フォーマット変換（Markdown → HTML）
- コードスニペット挿入
- テンプレート適用

**特徴**:
- インラインで即座に結果が欲しい
- 会話の流れを止めたくない
- 現在のコンテキストを保持したまま実行

#### 4. 参照知識の提供

**良い例（Skill）**:
- BigQueryのテーブルスキーマ
- REST APIエンドポイント一覧
- セキュリティベストプラクティス
- 正規表現パターン集

**特徴**:
- 主に`references/`ディレクトリを活用
- オンデマンドで読み込まれる
- SKILL.md自体は500行以内

### Subagents の特徴

#### 1. 複数ステップのワークフロー

**良い例（Subagent）**:
```
1. リポジトリ構造を調査
2. 依存関係を分析
3. ドキュメントを生成
4. テストカバレッジをチェック
5. 最終レポート作成
```

**キーワード**:
- "Phase 1", "Phase 2"
- "workflow", "pipeline"
- "first, then, finally"
- 条件分岐を含む手順

#### 2. 大量出力を生成

**良い例（Subagent）**:
- ログファイル解析（数千行の出力）
- コードベース全体のリファクタリング
- 大規模データセットの処理
- 包括的なセキュリティ監査レポート

**特徴**:
- 親の会話コンテキストを汚染したくない
- 結果を別のトランスクリプトに分離
- 最終的なサマリーだけを親に返す

#### 3. 並列・独立した調査

**良い例（Subagent）**:
- 複数のAPI仕様を同時に調査
- 複数のコードパスを並行分析
- 複数のウェブソースから情報収集

**特徴**:
- `Task`ツールで複数のsubagentを起動
- 各調査が独立して進行
- 結果を統合して親に報告

#### 4. 厳密なツール制限

**良い例（Subagent）**:
```yaml
tools: ["Read", "Grep", "Glob"]  # 読み取り専用
disallowedTools: ["Write", "Edit", "Bash"]
```

**用途**:
- 探索タスク（変更不可）
- セキュリティ監査（影響範囲制限）
- 読み取り専用分析

**特徴**:
- frontmatterで`tools`または`disallowedTools`を明示
- セキュリティや安全性が重要
- 親のツールセットより制限的

## 実際の例による判定

### 例1: fast-onboard

**現在**: Skill
**判定**: ✅ **適切**

**理由**:
- リポジトリ分析 → repo-analyzerサブエージェントに**委譲**
- fast-onboard自体は軽量なオーケストレーター
- `tools: ["Bash", "Read", "Task"]`
- スクリプト実行 + サブエージェント起動

**評価**: Skillとして正しい。実際の重い処理はsubagentに委譲している。

### 例2: session-bridge

**現在**: Skill
**判定**: ⚠️ **要検討**

**特徴**:
- 複数ステップのワークフロー（コンテキスト収集 → メモリ検索 → 再開）
- `allowed-tools: [Bash, Read]`（制限的）
- SessionStart hookと連動

**検討点**:
- 現在はインラインで実行（ユーザーの会話コンテキストで）
- hookから起動されるため、Skillが適切
- ただし、複雑さが増したらsubagent化を検討

**評価**: 現状はSkillで妥当だが、成長に注意。

### 例3: claude-code-subagent-builder

**現在**: Skill
**判定**: ⚠️ **境界線上**

**特徴**:
- サブエージェント定義を作成・編集
- 対話的な要件ヒアリング
- `AskUserQuestion`を使用する可能性
- ファイル生成・編集

**検討点**:
- インタラクティブなワークフロー
- ただし、現在の会話コンテキストで実行したい
- ユーザーとの対話を保持

**評価**: Skillで妥当。ユーザーとの対話が重要なため。

### 例4: deep-researcher

**現在**: Subagent
**判定**: ✅ **適切**

**理由**:
- 複数ステップのワークフロー（Phase 1-4）
- 大量のウェブ検索結果を生成
- 独立したコンテキストで実行
- `tools: ["WebSearch", "WebFetch", "Read", "Write"]`（制限的）

**評価**: Subagentとして正しい。

### 例5: repo-analyzer

**現在**: Subagent
**判定**: ✅ **適切**

**理由**:
- 複雑な分析ワークフロー
- 大量のファイル読み取り
- 長いCLAUDE.mdを生成
- `tools: ["Read", "Grep", "Glob", "Bash"]`（書き込み不可）

**評価**: Subagentとして正しい。

### 例6: skill-reviewer

**現在**: Subagent
**判定**: ✅ **適切**

**理由**:
- Phase 1-4の詳細なワークフロー
- ベストプラクティスファイルの読み込みと比較
- 詳細なレポート生成
- 編集も可能（`tools`に`Edit`含む）

**評価**: Subagentとして正しい。

## 誤分類のシグナル

### Skillなのにこれらがあれば要注意

- ❌ `tools`フィールドで厳密に制限している
- ❌ 本文に"Phase 1", "Phase 2"等の複数ステップ
- ❌ `Task`ツールを使って他のsubagentを起動
- ❌ 数百行のレポートを生成する記述
- ❌ "workflow", "pipeline"のキーワード多用

### Subagentなのにこれらがあれば要注意

- ❌ 主に参照知識の提供（`references/`だけ）
- ❌ ツール使用がほとんどない
- ❌ 単一の変換タスクのみ
- ❌ "Quick reference", "Style guide"等のタイトル
- ❌ 500行未満のシンプルな指示

## 境界線上のケース

### context: fork を使うSkill

```yaml
name: my-skill
context: fork
```

**判定**: Skillのまま可

**理由**:
- `context: fork`はSkillを一時的にsubagent化
- ユーザーからは`/my-skill`で起動
- 必要に応じて独立コンテキスト実行

**用途**:
- 通常はインラインで十分
- 大量出力時のみfork
- 柔軟性を保ちたい

### agent フィールドを使うSkill

```yaml
name: my-skill
agent: specific-subagent
```

**判定**: Skillのまま可

**理由**:
- Skillは単にエントリーポイント
- 実際の処理はsubagentに委譲
- ユーザーはSkillとして認識

**用途**:
- 複雑なsubagentへの簡易インターフェース
- ユーザーフレンドリーなコマンド名

## まとめ：分類の決定木

```
あなたの設定は...

1. 主に参照知識を提供？
   YES → Skill（references/を活用）

2. 単一の明確な変換タスク？
   YES → Skill（scriptsを活用）

3. ツール制限が必要で、独立した調査？
   YES → Subagent（tools: [...]）

4. 複数ステップのワークフロー？
   YES → Subagent（Phase 1-N）

5. 大量の出力を生成？
   YES → Subagent（親を汚染しない）

6. 並列の独立タスクを起動？
   YES → Subagent（Taskツール使用）

7. ユーザーとの対話が重要？
   YES → Skill（インライン実行）

8. 上記のいずれでもない？
   → デフォルトはSkill（よりシンプル）
```

## 公式ガイドラインのURL

- Skills: https://code.claude.com/docs/en/skills
- Subagents: https://code.claude.com/docs/en/sub-agents
- Best Practices: https://www.anthropic.com/engineering/claude-code-best-practices
