# Deployment Checklist

## Pre-Deployment ✓

- [ ] Verify `RAILS_MASTER_KEY` is configured in Kamal secrets
- [ ] Ensure Node.js and npm are included in Dockerfile
- [ ] Confirm Playwright is installed in Docker image (`package.json` includes playwright)
- [ ] Check database configuration in `config/database.yml`
- [ ] Review `config/recurring.yml` - weekly schedule on Mondays at 2 AM
- [ ] Verify `SOLID_QUEUE_IN_PUMA: true` in `config/deploy.yml`

## Deployment Steps ✓

```bash
# 1. Deploy the application
bin/kamal deploy

# 2. Verify deployment
bin/kamal app logs

# 3. Check application is running
curl https://your-domain.com
```

## Post-Deployment (REQUIRED) ✓

### Initial Data Setup

```bash
# Run the initial setup (THIS IS REQUIRED!)
bin/kamal app exec 'bin/rails portfolios:setup'
```

**What this does:**
- Fetches portfolios from GitHub (~100 portfolios)
- Saves them to production database
- Generates screenshots in batches (10 at a time with 30s delays)
- Takes approximately 20-30 minutes

**While it runs:**
- Monitor logs: `bin/kamal app logs -f`
- Jobs are processed in background by Solid Queue
- You can close the SSH session - jobs will continue

### Verify Setup

```bash
# Check portfolio count
bin/kamal app exec 'bin/rails portfolios:show'

# Check screenshot count
bin/kamal app exec 'bin/rails runner "puts Portfolio.with_attached_site_screenshot.count"'

# Check job queue
bin/kamal app exec 'bin/rails runner "puts SolidQueue::Job.count"'
```

**Expected results:**
- ~100 active portfolios in database
- ~100 screenshots attached
- Job queue should process and clear over time

## Testing the Application ✓

```bash
# 1. Test web interface
curl https://your-domain.com

# 2. Test JSON API
curl https://your-domain.com/portfolios.json

# 3. Verify screenshots are serving
# Visit the site in browser and check portfolio cards show images
```

## Ongoing Maintenance ✓

### Automatic (No Action Needed)

- ✅ **Weekly refresh**: Runs every Monday at 2 AM
- ✅ **Screenshot updates**: Generated in batches automatically
- ✅ **Queue cleanup**: Solid Queue cleans finished jobs hourly

### Manual Operations (As Needed)

```bash
# Manually trigger refresh
bin/kamal app exec 'bin/rails runner "FetchDeveloperPortfoliosJob.perform_later"'

# Regenerate specific screenshot
bin/kamal app exec 'bin/rails runner "GeneratePortfolioScreenshotJob.perform_later(123)"'

# Force full screenshot regeneration
bin/kamal app exec 'bin/rails portfolios:generate_screenshots'
```

## Monitoring ✓

### Regular Checks (Weekly)

```bash
# Portfolio count (should stay relatively stable)
bin/kamal app exec 'bin/rails portfolios:show'

# Failed jobs (should be minimal)
bin/kamal app exec 'bin/rails runner "puts SolidQueue::FailedExecution.count"'

# Application logs
bin/kamal app logs | tail -100
```

### Performance Monitoring

- **CPU usage**: Should spike during screenshot generation
- **Memory**: Monitor during batch processing
- **Disk space**: Screenshots stored in Active Storage
- **Job queue**: Check Solid Queue table sizes

## Troubleshooting ✓

### Issue: Screenshots not generating

**Solution:**
```bash
# Check Node.js is available
bin/kamal app exec 'node --version'

# Check Playwright is installed
bin/kamal app exec 'npm list playwright'

# View screenshot job errors
bin/kamal app logs | grep GeneratePortfolioScreenshotJob | grep ERROR
```

### Issue: Job queue stuck

**Solution:**
```bash
# Restart application (restarts Solid Queue)
bin/kamal app restart

# Or restart just the web container
bin/kamal app stop && bin/kamal app start
```

### Issue: Database connection errors

**Solution:**
```bash
# Check database is accessible
bin/kamal app exec 'bin/rails db:migrate:status'

# Run any pending migrations
bin/kamal app exec 'bin/rails db:migrate'

# Verify database host in environment
bin/kamal app exec 'bin/rails runner "puts ActiveRecord::Base.connection_db_config.host"'
```

### Issue: Out of memory during screenshot generation

**Solution:**

1. **Reduce batch size** in `app/jobs/fetch_developer_portfolios_job.rb`:
   ```ruby
   BATCH_SIZE = 5         # Smaller batches
   DELAY_SECONDS = 60     # Longer delays
   ```

2. **Reduce job concurrency** in `config/queue.yml`:
   ```yaml
   workers:
     - threads: 2         # Reduce from 3 to 2
   ```

3. **Increase server resources** or upgrade server plan

## Documentation References ✓

- **Quick commands**: [POST_DEPLOYMENT.md](POST_DEPLOYMENT.md)
- **Detailed guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Application README**: [README.md](README.md)

## Success Criteria ✓

Deployment is successful when:

- ✅ Application responds at your domain
- ✅ JSON API returns portfolio data: `GET /portfolios.json`
- ✅ ~100 portfolios visible in the UI
- ✅ Screenshot images display on portfolio cards
- ✅ Job queue is processing (check logs)
- ✅ Weekly job is scheduled (check `config/recurring.yml`)

---

## Emergency Rollback ✓

If something goes wrong:

```bash
# Rollback to previous version
bin/kamal rollback

# Check status
bin/kamal app logs
```

---

**Remember**: The `portfolios:setup` task is REQUIRED after first deployment to populate the database with portfolios and screenshots!

