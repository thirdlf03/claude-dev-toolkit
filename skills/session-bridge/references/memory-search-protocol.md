# Memory Search Protocol

Reference for efficient claude-mem MCP API usage.

## 3-Layer Progressive Disclosure

The claude-mem MCP API uses a 3-layer workflow for efficient token usage:

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: search()                                           │
│ - Returns: ID index with minimal metadata                   │
│ - Cost: ~50-100 tokens per result                          │
│ - Purpose: Find candidate observations                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: timeline()                                         │
│ - Returns: Context around anchor observation                │
│ - Cost: Moderate (depends on depth)                        │
│ - Purpose: Understand temporal context                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: get_observations()                                 │
│ - Returns: Full observation details                         │
│ - Cost: Full content tokens                                │
│ - Purpose: Get complete information for filtered IDs        │
└─────────────────────────────────────────────────────────────┘
```

## Token Efficiency

| Approach | Token Cost | Efficiency |
|----------|------------|------------|
| Direct get_observations (50 items) | ~50,000 tokens | Baseline |
| 3-layer protocol (filter to 5 items) | ~5,000 tokens | **10x savings** |

**Rule**: Never fetch all observations. Always filter first.

## Search Parameters

### search()

Full name: `mcp__plugin_claude-mem_mcp-search__search`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| query | string | Yes | Full-text search keywords |
| limit | number | No | Max results (default: 20, max: 100) |
| project | string | No | Filter by project name |
| type | string | No | Filter by observation type |
| obs_type | string | No | Alias for type |
| dateStart | ISO8601 | No | Start date (inclusive) |
| dateEnd | ISO8601 | No | End date (inclusive) |
| offset | number | No | Skip N results (pagination) |
| orderBy | string | No | Sort order (e.g., "created_at DESC") |

**Example**:
```json
{
  "query": "incomplete task test-fast-init",
  "project": "test-fast-init",
  "type": "session-request",
  "dateStart": "2026-01-28T00:00:00Z",
  "limit": 20
}
```

### timeline()

Full name: `mcp__plugin_claude-mem_mcp-search__timeline`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| anchor | number | Yes* | Observation ID to center on |
| query | string | Yes* | Alternative: find anchor automatically |
| depth_before | number | No | Observations before anchor (default: 3) |
| depth_after | number | No | Observations after anchor (default: 3) |
| project | string | No | Filter by project |

*Either `anchor` or `query` is required.

**Example**:
```json
{
  "anchor": 1234,
  "depth_before": 5,
  "depth_after": 5
}
```

### get_observations()

Full name: `mcp__plugin_claude-mem_mcp-search__get_observations`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| ids | number[] | Yes | Array of observation IDs to fetch |
| orderBy | string | No | Sort order |
| limit | number | No | Max results |
| project | string | No | Filter by project |

**Example**:
```json
{
  "ids": [1234, 1235, 1240]
}
```

## Observation Types

### Type Symbols

| Symbol | Type Name | Description |
|--------|-----------|-------------|
| session-request | Session Tasks | User requests that span sessions |
| bugfix | Bug Fixes | Resolved bugs and solutions |
| decision | Decisions | Architectural/design decisions |
| discovery | Discoveries | Research findings, insights |
| feature | Features | New functionality implemented |
| change | Changes | General code modifications |
| refactor | Refactoring | Code restructuring |

### Type Selection Guide

| Use Case | Recommended Type Filter |
|----------|------------------------|
| Find incomplete work | `session-request` |
| Learn from past bugs | `bugfix` |
| Recall why we did X | `decision` |
| Reuse research | `discovery` |
| Track implementations | `feature` |
| Find related changes | `change` |

## Best Practices

### Efficient Searching

1. **Start narrow, then broaden**
   - Begin with specific query + project + type
   - Remove filters if no results

2. **Use timeline for context**
   - Don't fetch all observations immediately
   - Timeline provides surrounding context efficiently

3. **Batch get_observations calls**
   - Collect all needed IDs first
   - Make single call with array of IDs
