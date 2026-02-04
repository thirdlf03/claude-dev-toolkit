# Troubleshooting Guide

Common issues and solutions for session bridging.

## Network Errors

### Problem: MCP server unreachable

**Symptoms**:
- Timeout errors when calling search/timeline/get_observations
- Connection refused errors

**Solutions**:
1. Check if MCP server is running
   ```bash
   # Check Claude Code MCP server status
   ps aux | grep claude-mem
   ```

2. Retry with exponential backoff
   - Wait 1s, then 2s, then 4s between retries
   - Maximum 3 retry attempts

3. Fall back to local context only
   - Use only collect_context.sh output
   - Skip memory search
   - Inform user of limited functionality

4. Restart Claude Code
   - MCP server may have crashed
   - Fresh start usually resolves connection issues

## Search Result Issues

### Problem: No observations found

**Symptoms**:
- Search returns empty results
- "No matching observations" message

**Solutions**:
1. Broaden date range
   ```json
   {
     "dateStart": "2026-01-21T00:00:00Z"  // 14 days instead of 7
   }
   ```

2. Remove type filter
   ```json
   {
     "query": "incomplete task my-project"
     // Remove: "type": "session-request"
   }
   ```

3. Try alternative query terms
   - "incomplete" → "in progress" or "pending"
   - "task" → "work" or "feature"

4. Check project name spelling
   - Verify exact match with project name from collect_context.sh
   - Try without project filter

5. Search without project filter
   ```json
   {
     "query": "incomplete task"
     // Remove: "project": "..."
   }
   ```

### Problem: Too many results

**Symptoms**:
- Search returns 100+ results
- Results are not relevant

**Solutions**:
1. Add project filter
   ```json
   {
     "project": "test-fast-init"
   }
   ```

2. Narrow date range
   ```json
   {
     "dateStart": "2026-02-01T00:00:00Z"  // Last 3 days
   }
   ```

3. Add type filter
   ```json
   {
     "type": "session-request"
   }
   ```

4. Use more specific query terms
   - "task" → "session-bridge implementation task"
   - Add keywords from current work

5. Reduce limit parameter
   ```json
   {
     "limit": 10  // Instead of default 20
   }
   ```

### Problem: Invalid observation IDs

**Symptoms**:
- get_observations returns errors
- "Observation not found" messages

**Solutions**:
1. Re-run search to get fresh IDs
   - IDs may have changed due to memory reorganization
   - Always use search results from current session

2. Filter out stale IDs
   - Remove IDs that return errors
   - Continue with valid IDs

3. Handle gracefully with partial results
   - Don't fail entire operation if some IDs are invalid
   - Present available information to user

## Script Execution Issues

### Problem: collect_context.sh fails

**Symptoms**:
- Script exits with error
- No JSON output

**Solutions**:
1. Check permissions
   ```bash
   chmod +x .claude/skills/session-bridge/scripts/collect_context.sh
   ```

2. Run from project root
   ```bash
   cd /path/to/project
   bash .claude/skills/session-bridge/scripts/collect_context.sh
   ```

3. Check for missing commands
   ```bash
   # For jj projects
   command -v jj || echo "jj not installed"

   # For git projects
   command -v git || echo "git not installed"
   ```

4. View stderr for error details
   ```bash
   bash .claude/skills/session-bridge/scripts/collect_context.sh 2>&1
   ```

### Problem: Script output is malformed

**Symptoms**:
- JSON parse errors
- Missing fields in output

**Solutions**:
1. Verify script version
   - Ensure you're using the latest version
   - Check for recent updates

2. Test in isolation
   ```bash
   # Test each function separately
   bash -x .claude/skills/session-bridge/scripts/collect_context.sh
   ```

3. Check for special characters
   - Project names with quotes or spaces may cause issues
   - Verify JSON escaping

## Performance Issues

### Problem: Slow response times

**Symptoms**:
- Search takes > 5 seconds
- Timeline requests timeout

**Solutions**:
1. Reduce limit parameter
   ```json
   {
     "limit": 10  // Smaller result set
   }
   ```

2. Use timeline instead of get_observations for initial context
   - Timeline is more efficient for browsing
   - Only fetch full observations for final selections

3. Check network connectivity to MCP server
   - Network latency may be issue
   - Check Claude Code logs for slow requests

4. Use more specific queries
   - Narrow search scope with filters
   - Reduces processing time

## SessionStart Hook Issues

### Problem: Hook doesn't execute

**Symptoms**:
- No context output on session start
- Hook appears configured but doesn't run

**Solutions**:
1. Verify settings.json syntax
   ```bash
   # Validate JSON
   python3 -m json.tool ~/.claude/settings.json
   ```

2. Check hook path
   ```json
   {
     "command": "bash .claude/skills/session-bridge/scripts/collect_context.sh"
     // Use relative path, not absolute
   }
   ```

3. Check hook timeout
   ```json
   {
     "timeout": 10  // Increase if script is slow
   }
   ```

4. View Claude Code logs
   - Check for hook execution errors
   - Verify hook is being triggered

## Getting Help

If issues persist:

1. Check Claude Code documentation
   - https://github.com/anthropics/claude-code

2. Review skill-reviewer feedback
   - Run skill-reviewer agent for diagnostics

3. Enable debug logging
   - Check Claude Code logs for detailed errors

4. Create minimal reproduction
   - Test with simple project
   - Isolate specific failing component
