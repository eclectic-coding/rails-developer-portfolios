# Troubleshooting Background Jobs

## Quick Diagnostic

Run this to get a full overview of your job system:

```bash
rails jobs:diagnostic
```

## Common Issues on Hatchbox

### 1. Workers Crashing on Startup

**Symptom:** Workers restart repeatedly, jobs never process.

**Check logs:**
```bash
sudo journalctl -u young-star-6591-solid_queue.service -n 50
```

**Common causes:**
- Invalid recurring schedule format (use `bin/validate-schedules` to check)
- Database connection issues
- Missing environment variables

### 2. Workers Not Running

**Symptom:** `rails jobs:workers` shows no active workers.

**Solution:** On Hatchbox, ensure:
- Your Procfile includes a worker process
- Background workers are enabled in Hatchbox app settings
- Check Hatchbox logs for worker startup errors

### 3. Jobs Stuck in Queue

**Symptom:** Many pending jobs but workers are running.

**Solution:**
```bash
# Check for failed jobs
rails jobs:failed

# Retry failed jobs
rails jobs:retry_failed
```

## Individual Commands

### Check if workers are running
```bash
rails jobs:workers
```

### Check job status
```bash
rails jobs:status
```

### Check failed jobs
```bash
rails jobs:failed
```

### Check portfolios without screenshots
```bash
rails jobs:missing_screenshots
```

### Retry failed jobs
```bash
rails jobs:retry_failed
```

### Validate recurring schedules
```bash
bin/validate-schedules
```

## Manual Job Queue

Re-queue screenshots for portfolios that are missing them:

```bash
rails runner "Portfolio.active.reject { |p| p.site_screenshot.attached? }.each { |p| GeneratePortfolioScreenshotJob.perform_later(p.id) }"
```

Or use the batch approach:

```bash
rails portfolios:generate_screenshots BATCH_SIZE=10 DELAY_SECONDS=30
```

## Checking on Hatchbox

SSH into your Hatchbox instance and run:

```bash
cd /home/deploy/[your-app-name]/current
bin/rails jobs:diagnostic
```

Or check the Rails console:

```bash
bin/rails console

# Check jobs directly
SolidQueue::Job.where(finished_at: nil).count
SolidQueue::FailedExecution.count

# Check workers
SolidQueue::Process.where("last_heartbeat_at > ?", 5.minutes.ago).count
```

## Viewing Logs

On Hatchbox:
```bash
# Worker logs
sudo journalctl -u young-star-6591-solid_queue.service -f

# Application logs
tail -f log/production.log
```

Look for errors related to:
- `GeneratePortfolioScreenshotJob`
- `PortfolioScreenshotGenerator`
- Database connection issues
- Invalid recurring schedules

## Nuclear Option: Restart Everything

If jobs are completely stuck:

1. On Hatchbox dashboard, restart your app
2. Clear and re-queue jobs:

```bash
rails runner "SolidQueue::Job.where(finished_at: nil).delete_all"
rails portfolios:generate_screenshots
```

## Getting Help

When reporting issues, include output from:
```bash
rails jobs:diagnostic
rails jobs:failed
sudo journalctl -u young-star-6591-solid_queue.service -n 100
```

