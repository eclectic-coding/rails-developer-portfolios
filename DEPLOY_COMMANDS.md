# Quick Deploy Commands - Copy & Paste

## 1. Commit and Push (Run locally)

```bash
cd /Users/eclecticcoding/Desktop/rails_developer_portfolios

git add -A

git commit -m "Fix: Invalid recurring schedule causing Solid Queue worker crash loop

- Changed schedule from 'every week on Monday at 2am' to 'every Monday at 2am'
- Added Procfile with worker process definition
- Created bin/validate-schedules for schedule validation
- Added comprehensive job diagnostic tools (rails jobs:*)
- Added Hatchbox setup script and documentation"

git push origin main
```

## 2. Enable Workers in Hatchbox (Web UI)

1. Go to Hatchbox dashboard
2. Select your app
3. Click "Processes" or "Workers"
4. Enable the "worker" process
5. Deploy

## 3. Verify on Hatchbox (SSH)

```bash
# SSH to your server (use your actual Hatchbox SSH command)

# Check worker logs - NO crash loop
sudo journalctl -u young-star-6591-solid_queue.service -n 50

# Navigate to app
cd /home/deploy/[your-app-name]/current

# Check workers are running
bin/rails jobs:workers

# Should see: "✓ Active workers found: 1"
```

## 4. Re-queue Screenshots (After Installing Playwright)

```bash
# In your app directory
bin/rails portfolios:generate_screenshots BATCH_SIZE=10 DELAY_SECONDS=30

# Monitor progress
bin/rails jobs:status
```

## 5. Watch Progress (Optional)

```bash
# Real-time monitoring
watch -n 5 'bin/rails jobs:status'

# Or check manually
bin/rails jobs:missing_screenshots
```

---

## What Fixed It

**Problem:** `every week on Monday at 2am` ❌ (invalid Fugit syntax)
**Solution:** `every Monday at 2am` ✅ (valid Fugit syntax)

Workers were crashing immediately on startup because of invalid schedule format.

---

## New Commands Available After Deploy

```bash
bin/rails jobs:diagnostic              # Full overview
bin/rails jobs:workers                 # Worker status
bin/rails jobs:status                  # Job queue
bin/rails jobs:failed                  # View failures
bin/validate-schedules                 # Validate config
```

---

**That's it! Copy the commands above and you're good to go! 🚀**

