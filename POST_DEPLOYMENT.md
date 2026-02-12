# Post-Deployment Quick Reference

## 🚀 Initial Setup (Run Once After Deployment)

```bash
bin/kamal app exec 'bin/rails portfolios:setup'
```

This single command will:
- ✅ Fetch all portfolios from GitHub
- ✅ Save them to the database
- ✅ Generate screenshots in batches (10 at a time, 30s delays)
- ✅ Prevent resource overload

**Expected time**: 20-30 minutes for ~100 portfolios

---

## 📋 Common Commands

### Check Status
```bash
# View portfolio stats
bin/kamal app exec 'bin/rails portfolios:show'

# Check job queue
bin/kamal app exec 'bin/rails runner "puts SolidQueue::Job.count"'
```

### Manual Operations
```bash
# Update portfolios only (no screenshots)
bin/kamal app exec 'bin/rails portfolios:fetch'

# Regenerate all screenshots
bin/kamal app exec 'bin/rails portfolios:generate_screenshots'

# Custom batch settings (smaller batches, longer delays)
bin/kamal app exec 'bin/rails portfolios:generate_screenshots BATCH_SIZE=5 DELAY_SECONDS=60'
```

### View Logs
```bash
# Real-time logs
bin/kamal app logs -f

# Search for errors
bin/kamal app logs | grep ERROR
```

---

## 🔄 Automatic Updates

**Schedule**: Every Monday at 2 AM
**Configuration**: `config/recurring.yml`

The weekly job automatically:
1. Fetches new/updated portfolios
2. Generates screenshots in batches (resource-friendly)

No manual intervention needed! ✨

---

## ⚙️ Resource Management

### Current Settings (Default)
- **Batch size**: 10 portfolios per batch
- **Delay**: 30 seconds between batches
- **Job threads**: 3 concurrent jobs

### Adjust If Needed

**For lower-resource servers**, edit `app/jobs/fetch_developer_portfolios_job.rb`:
```ruby
BATCH_SIZE = 5         # Smaller batches
DELAY_SECONDS = 60     # Longer delays
```

**For higher-resource servers**:
```ruby
BATCH_SIZE = 20        # Larger batches
DELAY_SECONDS = 15     # Shorter delays
```

---

## 🆘 Troubleshooting

### Screenshots Not Generating?

1. **Check Node.js**: `bin/kamal app exec 'node --version'`
2. **Check Playwright**: `bin/kamal app exec 'npm list playwright'`
3. **View failed jobs**: `bin/kamal app logs | grep GeneratePortfolioScreenshotJob`

### Job Queue Stuck?

```bash
# Restart application (restarts Solid Queue)
bin/kamal app restart
```

### Need More Details?

See full [Deployment Guide](DEPLOYMENT_GUIDE.md) for comprehensive documentation.

---

## 📊 What to Expect

| Operation | Time |
|-----------|------|
| Portfolio fetch | ~5-10 seconds |
| Single screenshot | ~2-5 seconds |
| Full setup (100 portfolios) | ~20-30 minutes |
| Weekly refresh | ~20-30 minutes |

**Note**: Times vary based on server resources and network speed.

