# Screenshot Jobs Status - CRITICAL FIX APPLIED ✅

## 🔥 The ACTUAL Problem (Root Cause Found!)

Based on your server logs, Solid Queue workers are **crashing immediately on startup** with this error:

```
Invalid recurring tasks:
- fetch_developer_portfolios: Schedule is not a supported recurring schedule
Exiting...
young-star-6591-solid_queue.service: Failed with result 'exit-code'.
```

## 🎯 Root Causes Identified

1. ❌ **INVALID RECURRING SCHEDULE** (Primary issue - causes crash loop)
   - Format: `every week on Monday at 2am` is NOT valid for Fugit
   - Workers exit immediately, can't process any jobs

2. ❌ **Missing Worker Process in Procfile** (Secondary issue)
   - Even if schedule was fixed, Hatchbox wouldn't know to start workers

## ✅ What I've Fixed

### 1. Fixed the Invalid Schedule Format

**File:** `config/recurring.yml`

**Changed:**
```yaml
# BEFORE (❌ INVALID - causes crash)
fetch_developer_portfolios:
  class: FetchDeveloperPortfoliosJob
  schedule: every week on Monday at 2am

# AFTER (✅ VALID - works with Fugit)
fetch_developer_portfolios:
  class: FetchDeveloperPortfoliosJob
  schedule: every Monday at 2am
```

### 2. Created Production Procfile

**File:** `Procfile`
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec rake solid_queue:start
```

### 3. Created Schedule Validation Tool

**File:** `bin/validate-schedules`

Validate your recurring schedules:
```bash
bin/validate-schedules
```

## 🚀 Deploy These Fixes NOW

### Step 1: Commit and Push
```bash
git add Procfile config/recurring.yml bin/validate-schedules bin/hatchbox-setup lib/tasks/jobs.rake
git commit -m "Fix: Invalid recurring schedule causing worker crashes"
git push
```

### Step 2: Enable Workers in Hatchbox
1. Open Hatchbox dashboard
2. Go to your app → **Processes** section
3. Enable the `worker` process
4. Deploy/Restart

### Step 3: Verify on Hatchbox

SSH into your server:
```bash
# Check system logs for the worker
sudo journalctl -u young-star-6591-solid_queue.service -n 50

# Should see successful startup, NOT "Invalid recurring tasks"
```

Then check job status:
```bash
cd /home/deploy/[your-app-name]/current
bin/rails jobs:diagnostic
```

**Expected output:**
```
✓ Active workers found: 1
  Last heartbeat: 2026-02-19 [recent time]
```

## 🔄 Re-queue Screenshot Jobs

Once workers are running:

```bash
# On Hatchbox
bin/rails portfolios:generate_screenshots BATCH_SIZE=10 DELAY_SECONDS=30
```

Or target only portfolios without screenshots:
```bash
bin/rails runner "Portfolio.active.reject { |p| p.site_screenshot.attached? }.each { |p| GeneratePortfolioScreenshotJob.perform_later(p.id) }"
```

## 🛠️ New Tools Available

### Diagnostic Commands
```bash
bin/rails jobs:diagnostic              # Full system check
bin/rails jobs:workers                 # Check worker status
bin/rails jobs:status                  # Job queue status
bin/rails jobs:failed                  # View failed jobs
bin/rails jobs:missing_screenshots     # Portfolios without screenshots
bin/validate-schedules                 # Validate recurring.yml
```

## 📝 Summary

**Problem:** Invalid schedule format caused worker crash loop
**Solution:** Changed `every week on Monday at 2am` → `every Monday at 2am`
**Status:** ✅ Fixed and ready to deploy

The workers couldn't start because the config was invalid. Jobs were queuing but had no workers to process them.

---

**TL;DR:** Deploy the fix, enable workers in Hatchbox, re-queue screenshots! 🚀

