# 🎯 Jobs Management - Complete Setup

## ✅ What's Been Added

### 1. Rake Tasks (lib/tasks/jobs.rake)

**10 new commands** to manage jobs on your server:

#### Main Commands
- `rails jobs:update_feed` - **Primary command** to update feed and queue screenshots
- `rails jobs:run_all` - Same as update_feed with extra output
- `rails jobs:generate_screenshots` - Queue screenshots for all portfolios
- `rails jobs:generate_screenshot[ID]` - Screenshot for specific portfolio

#### Monitoring Commands
- `rails jobs:diagnostic` - Full system health check
- `rails jobs:status` - Job queue status
- `rails jobs:workers` - Check if workers are running
- `rails jobs:failed` - Show failed jobs with details
- `rails jobs:missing_screenshots` - Find portfolios without screenshots

#### Maintenance Commands
- `rails jobs:retry_failed` - Retry all failed jobs

### 2. Documentation Files

| File | Purpose |
|------|---------|
| `JOBS_CHEATSHEET.md` | Quick one-page reference |
| `JOBS_REFERENCE.md` | Comprehensive guide with examples |
| `DEPLOYMENT_JOBS_CHECKLIST.md` | Server deployment guide |
| `README_JOBS.md` | This summary file |

## 🚀 Quick Start on Server

```bash
# 1. SSH into your server
ssh deploy@your-server.com

# 2. Navigate to your app
cd /path/to/rails_developer_portfolios

# 3. Check that workers are running
bundle exec rake jobs:workers

# If workers aren't running, enable them in Hatchbox dashboard

# 4. Update feed and queue screenshots
bundle exec rake jobs:update_feed

# 5. Check progress
bundle exec rake jobs:status

# 6. Wait a few minutes, then check again
bundle exec rake jobs:diagnostic
```

**⚠️ Important:** Use `bundle exec rake` (not `rails`) for these custom tasks!

## 📚 Which Document Should I Use?

- **Just need commands?** → `JOBS_CHEATSHEET.md`
- **Need detailed info?** → `JOBS_REFERENCE.md`
- **Deploying or setup issues?** → `DEPLOYMENT_JOBS_CHECKLIST.md`
- **Overview?** → This file!

## 🔧 How It Works

1. **FetchDeveloperPortfoliosJob** fetches the feed and syncs portfolios
2. **GeneratePortfolioScreenshotJob** generates screenshots (batched, 10 at a time)
3. **Solid Queue** handles the job processing in the background
4. **Workers** process the jobs (must be running!)

## ✨ Key Features

- **Batched processing**: 10 portfolios at a time with 30-second delays
- **Error handling**: Failed jobs can be retried
- **Monitoring**: Multiple commands to check status
- **Manual control**: Run jobs on-demand without waiting for schedules

## ⚠️ Important Requirements

1. **Solid Queue workers must be running**
   - Check with: `rails jobs:workers`
   - Enable in Hatchbox dashboard
   - Verify in Procfile: `worker: bundle exec rake solid_queue:start` ✅

2. **Jobs are batched to prevent overload**
   - First 10 portfolios: immediate
   - Next batches: 30-second delays
   - This is by design - don't worry if not instant!

3. **Failed jobs need attention**
   - Check: `rails jobs:failed`
   - Fix underlying issues
   - Retry: `rails jobs:retry_failed`

## 📞 Troubleshooting

### Workers Not Running
```bash
bundle exec rake jobs:workers
# If shows "No active workers found":
# 1. Check Hatchbox - are background workers enabled?
# 2. Check Procfile (should be: worker: bundle exec rake solid_queue:start)
# 3. Redeploy the app
# 4. Check logs: tail -f log/production.log
```

### Jobs Stuck
```bash
bundle exec rake jobs:status     # See if jobs are pending
bundle exec rake jobs:failed     # Check for errors
bundle exec rake jobs:workers    # Verify workers are running
```

### Screenshots Missing
```bash
bundle exec rake jobs:missing_screenshots    # See which ones are missing
bundle exec rake jobs:generate_screenshots   # Generate them
```

## 🎓 Examples

### Daily Update Routine
```bash
bundle exec rake jobs:update_feed
# Wait 5-10 minutes
bundle exec rake jobs:diagnostic
```

### Fix Failed Jobs
```bash
bundle exec rake jobs:failed           # See what failed
# Fix the underlying issue (check URLs, network, etc.)
bundle exec rake jobs:retry_failed     # Retry them
bundle exec rake jobs:status           # Monitor progress
```

### Generate Screenshot for One Portfolio
```bash
bundle exec rake jobs:generate_screenshot[123]
# Replace 123 with actual portfolio ID
```

## 📅 Recommended Schedule

**Daily:** Run `bundle exec rake jobs:update_feed` once per day
- Keeps feed current
- Generates screenshots for new portfolios
- Can be automated with cron or Rails recurring jobs

**Weekly:** Run `bundle exec rake jobs:diagnostic` to check overall health

**As Needed:**
- `bundle exec rake jobs:retry_failed` if jobs fail
- `bundle exec rake jobs:generate_screenshots` to regenerate all screenshots

## 🎉 You're All Set!

Everything you need is now in place. Just:
1. Make sure workers are running on your server
2. Run `bundle exec rake jobs:update_feed` when you want to update
3. Use `bundle exec rake jobs:diagnostic` to check status

**Remember:** Use `bundle exec rake` (not `rails`) for these custom tasks on the server!

---

**Created:** May 6, 2026
**Server:** Hatchbox
**Background Jobs:** Solid Queue ✅
**Procfile:** Configured ✅
**Rake Tasks:** 10 commands added ✅
**Documentation:** 4 files created ✅

