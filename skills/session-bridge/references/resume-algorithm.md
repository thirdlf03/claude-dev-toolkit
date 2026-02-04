# Resume Detection Algorithm

Step-by-step algorithm for detecting and resuming incomplete work.

## Phase 1: Context Collection

```
1. Run collect_context.sh
2. Parse JSON output
3. Extract: project_name, vcs_status, date_range
```

**What it provides**:
- Current project name and type
- VCS status (git/jj branch, uncommitted changes)
- Suggested search date range (last 7 days)
- Pre-built search queries

## Phase 2: Memory Search

```
1. Search with filters:
   - query: "incomplete" OR "in_progress" OR "task"
   - project: <project_name>
   - dateStart: <7_days_ago>
   - type: "session-request"
   - limit: 20

2. Analyze results:
   - Look for session-request observations
   - Check for "incomplete", "in_progress", "pending" keywords
   - Note observation IDs of interest
```

**Search strategy**:
- Start with narrow filters (project + type + recent dates)
- If no results, broaden filters progressively
- Look for keywords indicating incomplete work

## Phase 3: Context Retrieval

```
1. For top 3-5 candidate IDs:
   - Call timeline(anchor: <id>, depth_before: 3, depth_after: 3)
   - Understand what led to the observation
   - See what happened after

2. Filter to most relevant IDs

3. Call get_observations(ids: <filtered_ids>)
   - Get full content for final review
```

**Filtering criteria**:
- Recency (prefer recent observations)
- Relevance to current project
- Status indicators (in_progress > pending > incomplete)
- File overlap with current uncommitted changes

## Phase 4: Resume Presentation

```
1. Summarize findings:
   - What task was in progress
   - Where it left off
   - What files were modified
   - What decisions were pending

2. Present options:
   - Resume from last point
   - Review history first
   - Start fresh
```

**Presentation format**:
- Clear summary of incomplete work
- Context of what was being done
- Specific next steps identified
- User choice for how to proceed

## Resume Flow Best Practices

1. **Always show options**
   - Don't auto-resume without confirmation
   - Present summary of what was found

2. **Preserve user control**
   - Let user choose what to resume
   - Allow "start fresh" option

3. **Inject context incrementally**
   - Don't dump all history at once
   - Provide context as needed during work

## Example Resume Flow

```
User: "前回の作業を再開して"

Claude:
1. Run collect_context.sh → Get project info
2. Search memory → Find 3 incomplete tasks
3. Timeline → Get context around each
4. Present summary:
   "前回は session-bridge スキルのレビュー修正を
    実施していました。優先度高の修正は完了しています。

    次の選択肢があります:
    1. 優先度中の修正を続ける
    2. 修正履歴を確認する
    3. 新しい作業を始める

    どうしますか？"
```
