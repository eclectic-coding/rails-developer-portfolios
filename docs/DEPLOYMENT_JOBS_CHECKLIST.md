# 📋 Server Deployment Checklist for Jobs

## When You Deploy

After deploying to your server (Hatchbox), make sure:

### 1. ✅ Background Workers Are Enabled

In Hatchbox dashboard:
- Go to your app settings
- Enable "Background Workers" if not already enabled
- Verify the worker process is running

### 2. ✅ Verify Workers Are Running

SSH into your server and run:
```bash
cd /path/to/your-app
bundle exec rake jobs:workers
```

**Expected output:**
```
✓ Active workers found: 1
  PID: hostname:12345
  Last heartbeat: 2024-XX-XX XX:XX:XX
  Kind: Worker
```

**If you see "No active workers found":**
- Check Hatchbox dashboard - are background workers enabled?
- Check if the worker process crashed: `tail -f log/production.log`
- Restart the app in Hatchbox
- Check your `Procfile` has: `worker: bundle exec rake solid_queue:start`

### 3. ✅ Run Initial Update

After deployment or when workers are confirmed running:
```bash
bundle exec rake jobs:update_feed
```

### 4. ✅ Monitor Progress

```bash
# Check status every few minutes
bundle exec rake jobs:status

# Get full diagnostic
bundle exec rake jobs:diagnostic
```

## Your Procfile Configuration

```
web: bundle exec puma -C config/puma.rb
worker: bundle exec rake solid_queue:start
```

✅ This is correct - no changes needed!

## Common Issues

### "No active workers found"
**Problem:** Background workers aren't running
**Solution:**
1. Enable background workers in Hatchbox
2. Redeploy the app
3. Check logs for errors

### "Jobs stuck in pending"
**Problem:** Workers may be overwhelmed or crashed
**Solution:**
1. Check worker status: `bundle exec rake jobs:workers`
2. Check for errors: `bundle exec rake jobs:failed`
3. Restart workers via Hatchbox
4. May need to increase worker count in Hatchbox

### "Many failed jobs"
**Problem:** Network issues, timeouts, or invalid data
**Solution:**
1. Check failures: `bundle exec rake jobs:failed`
2. Fix underlying issue (network, URL validation, etc.)
3. Retry: `bundle exec rake jobs:retry_failed`

## Scheduled Jobs

If you want jobs to run automatically (e.g., daily updates):

1. **Option A: Cron Job (Recommended)**
   ```bash
   # Add to crontab (via Hatchbox or manually)
   0 2 * * * cd /path/to/app && bundle exec rake jobs:update_feed >> log/cron.log 2>&1
   ```
   This runs the update daily at 2 AM.

2. **Option B: Rails Recurring Job**
   Check `config/recurring.yml` - you may already have this configured!

## Quick Start After Deployment

```bash
# 1. SSH into server
ssh deploy@your-server.com

# 2. Navigate to app
cd /path/to/rails_developer_portfolios

# 3. Check workers are running
bundle exec rake jobs:workers

# 4. If workers are running, update feed
bundle exec rake jobs:update_feed

# 5. Monitor progress
bundle exec rake jobs:status

# 6. Check results after jobs complete
bundle exec rake jobs:diagnostic
```

**💡 Important:** Always use `bundle exec rake` (not `rails`) for these custom tasks!

## Need Help?

1. Check the full guide: `JOBS_REFERENCE.md`
2. Quick commands: `JOBS_CHEATSHEET.md`
3. Check Hatchbox documentation for background workers
4. Review Rails logs: `tail -f log/production.log`

---

**Last Updated:** May 2026
**Your Procfile:** ✅ Configured correctly
**Background Jobs:** Solid Queue
**Server:** Hatchbox

