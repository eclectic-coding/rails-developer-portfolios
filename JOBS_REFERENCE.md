# Jobs Management Reference Guide

Quick reference for manually running jobs on the server to update feeds and generate screenshots.

## 🚀 Quick Start (Most Common Use)

```bash
# SSH into your server, then:
cd /path/to/rails_developer_portfolios

# Update feed and queue all screenshot jobs
bundle exec rake jobs:update_feed

# Check status
bundle exec rake jobs:diagnostic
```

**⚠️ Important:** Use `bundle exec rake` (not `rails`) for these custom tasks on the server!

## 📋 Available Commands

### Main Commands

#### `bundle exec rake jobs:update_feed`
**Primary command** - Updates the feed and queues screenshot generation
- Fetches latest portfolios from the feed
- Syncs new/updated portfolios to database
- Automatically queues screenshot jobs for all active portfolios
- Use this when you want to refresh everything

#### `bundle exec rake jobs:run_all`
Same as `update_feed` but with additional diagnostic output at the end.

#### `bundle exec rake jobs:generate_screenshots`
Generate screenshots for all active portfolios without updating the feed
- Prompts for confirmation before queueing
- Useful if feed is already up-to-date but screenshots need regeneration

#### `bundle exec rake jobs:generate_screenshot[ID]`
Generate screenshot for a specific portfolio
```bash
# Example: Generate screenshot for portfolio ID 123
bundle exec rake jobs:generate_screenshot[123]
```

### Monitoring Commands

#### `bundle exec rake jobs:diagnostic`
**Full system health check** - Shows:
- Worker status (are background jobs running?)
- Job queue status (pending/failed/completed)
- Portfolio screenshot status

#### `bundle exec rake jobs:status`
Quick view of job queue status
- Total, pending, failed, and completed jobs
- Screenshot-specific job counts
- Recent pending jobs

#### `bundle exec rake jobs:workers`
Check if Solid Queue background workers are running
- Shows active worker processes
- Displays last heartbeat times
- Warns if no workers are found

#### `bundle exec rake jobs:failed`
Detailed view of failed jobs
- Shows error messages and backtraces
- Up to 20 most recent failures

#### `bundle exec rake jobs:missing_screenshots`
Lists portfolios that don't have screenshots yet

### Maintenance Commands

#### `bundle exec rake jobs:retry_failed`
Retry all failed jobs
- Automatically requeues any failed jobs
- Useful after fixing issues that caused failures

## 🔄 Common Workflows

### Daily/Weekly Update
```bash
# 1. Update everything
rails jobs:update_feed

# 2. Check that workers are processing
rails jobs:status

# 3. Wait a bit, then check again
# (Jobs are batched with delays to avoid overwhelming the server)
rails jobs:status

# 4. Check for any failures
rails jobs:failed
```

### Troubleshooting Stuck Jobs
```bash
# 1. Check full diagnostic
rails jobs:diagnostic

# 2. Check if workers are running
rails jobs:workers

# 3. If workers are down, restart them (Hatchbox)
# - Check Hatchbox dashboard
# - Redeploy if needed

# 4. Retry any failed jobs
rails jobs:retry_failed

# 5. Verify status
rails jobs:status
```

### Manual Screenshot Generation
```bash
# For all portfolios
rails jobs:generate_screenshots

# For a specific portfolio (no confirmation needed)
rails jobs:generate_screenshot[123]
```

## ⚠️ Important Notes

### Workers Must Be Running
Jobs won't process unless Solid Queue workers are running. Check with:
```bash
rails jobs:workers
```

If no workers are found:
1. Check your `Procfile` has: `jobs: bundle exec rails jobs:work`
2. Verify background workers are enabled in Hatchbox
3. Check deployment logs for errors
4. May need to redeploy

### Batching and Delays
Screenshot generation is batched (10 portfolios per batch) with 30-second delays between batches to avoid:
- Overwhelming server resources
- Screenshot service rate limits
- Browser/memory issues

This means:
- First 10 portfolios: process immediately
- Next 10 portfolios: wait 30 seconds
- Next 10 portfolios: wait 60 seconds
- And so on...

### Job Status Types

**Pending**: Queued but not yet processed
- Normal if workers are running and there's a backlog
- Concerning if stuck for hours

**Failed**: Job encountered an error
- Check error details with `rails jobs:failed`
- Common causes: network timeouts, invalid URLs, service errors
- Use `rails jobs:retry_failed` after fixing underlying issues

**Completed**: Successfully finished
- Screenshot should be attached to portfolio
- Visible on the site

## 🔍 Example Output

### Successful Update
```
============================================================
UPDATING FEED AND GENERATING SCREENSHOTS
============================================================

Starting FetchDeveloperPortfoliosJob...
This will:
  1. Fetch and sync portfolios from the feed
  2. Queue screenshot generation for active portfolios

✓ Feed update completed successfully!

Screenshot jobs have been queued.
Run 'rails jobs:status' to check their progress.
```

### Checking Status
```
============================================================
SOLID QUEUE JOB STATUS
============================================================

Overall Status:
  Total jobs:    150
  Pending:       45
  Failed:        2
  Completed:     103

Screenshot Jobs:
  Total:         123
  Pending:       45
  Completed:     76
```

## 📞 Getting Help

If you encounter issues:

1. **Run diagnostic**: `rails jobs:diagnostic`
2. **Check logs**: `tail -f log/production.log`
3. **Verify workers**: `rails jobs:workers`
4. **Review failures**: `rails jobs:failed`

For persistent issues, check:
- Server resources (RAM, CPU)
- Screenshot service availability
- Network connectivity
- Database connections

## 🎯 Summary

**Most common command you'll need:**
```bash
rails jobs:update_feed
```

**To check everything worked:**
```bash
rails jobs:diagnostic
```

**If something failed:**
```bash
rails jobs:retry_failed
```

That's it! 🎉

