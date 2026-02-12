# Deployment Guide

## Post-Deployment Setup

After deploying your application, follow these steps to initialize the portfolio data and screenshots.

### Step 1: Initial Data Population

SSH into your production server and run the initial setup task:

```bash
# Using Kamal
bin/kamal app exec 'bin/rails portfolios:setup'

# Or manually SSH and run
bin/rails portfolios:setup
```

This will:
1. Fetch all portfolios from the upstream GitHub repository
2. Save them to the database
3. Generate screenshots in batches (10 at a time with 30-second delays)

### Step 2: Monitor Progress

You can monitor the job queue:

```bash
# Using Kamal
bin/kamal app exec 'bin/rails runner "puts SolidQueue::Job.count"'

# Check recent jobs
bin/kamal app exec 'bin/rails runner "SolidQueue::Job.order(created_at: :desc).limit(10).pluck(:job_class, :status)"'
```

### Step 3: Verify Data

Check that portfolios and screenshots were created:

```bash
# View portfolio stats
bin/kamal app exec 'bin/rails portfolios:show'

# Check screenshot count
bin/kamal app exec 'bin/rails runner "puts Portfolio.active.with_attached_site_screenshot.count"'
```

## Manual Operations

### Fetch Portfolios Only (No Screenshots)

If you only want to update portfolio data without generating screenshots:

```bash
bin/kamal app exec 'bin/rails portfolios:fetch'
```

### Generate Screenshots Only

To generate screenshots for all active portfolios (in batches):

```bash
# Default: 10 per batch, 30 seconds between batches
bin/kamal app exec 'bin/rails portfolios:generate_screenshots'

# Custom batch size and delay
bin/kamal app exec 'bin/rails portfolios:generate_screenshots BATCH_SIZE=5 DELAY_SECONDS=60'
```

### Trigger Weekly Job Manually

To manually trigger the weekly refresh job:

```bash
bin/kamal app exec 'bin/rails runner "FetchDeveloperPortfoliosJob.perform_later"'
```

## Resource Management

The screenshot generation is resource-intensive. Here's how it's managed:

### Batching Configuration

- **Default batch size**: 10 portfolios
- **Default delay**: 30 seconds between batches
- **Job queue**: Runs through Solid Queue with 3 threads per worker

### Weekly Automatic Updates

The recurring job (Mondays at 2 AM) automatically:
1. Fetches new portfolios
2. Generates screenshots in batches (10 at a time, 30-second delays)

### Customizing Resource Usage

Edit the constants in `app/jobs/fetch_developer_portfolios_job.rb`:

```ruby
BATCH_SIZE = 10        # Number of screenshots per batch
DELAY_SECONDS = 30     # Seconds to wait between batches
```

Or adjust Solid Queue workers in `config/queue.yml`:

```yaml
workers:
  - queues: "*"
    threads: 3                                      # Concurrent jobs
    processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>  # Worker processes
```

## Troubleshooting

### Screenshots Failing

Check if Node.js and Playwright are installed:

```bash
bin/kamal app exec 'node --version'
bin/kamal app exec 'npm list playwright'
```

If missing, ensure your Dockerfile includes:

```dockerfile
RUN npm install
RUN npx playwright install --with-deps chromium
```

### Job Queue Stuck

Restart Solid Queue (automatically restarts with Puma):

```bash
bin/kamal app restart
```

View failed jobs:

```bash
bin/kamal app exec 'bin/rails runner "SolidQueue::FailedExecution.last(10).each { |f| puts f.inspect }"'
```

### Database Issues

Check database connection:

```bash
bin/kamal app exec 'bin/rails db:migrate:status'
```

Run pending migrations:

```bash
bin/kamal app exec 'bin/rails db:migrate'
```

## Production Monitoring

### Key Metrics to Monitor

1. **Portfolio count**: Should match upstream feed
2. **Screenshot success rate**: Check Active Storage attachments
3. **Job queue health**: Monitor Solid Queue table sizes
4. **Resource usage**: CPU/Memory during screenshot generation

### Logs

View application logs:

```bash
# Real-time logs
bin/kamal app logs -f

# Search for errors
bin/kamal app logs | grep ERROR

# Screenshot job logs
bin/kamal app logs | grep GeneratePortfolioScreenshotJob
```

## Recommended Setup Schedule

1. **Initial deployment**: Run `portfolios:setup` once
2. **Weekly**: Automatic job runs Monday at 2 AM
3. **Monthly**: Verify screenshot quality and success rate
4. **As needed**: Manually regenerate screenshots if issues found

## Performance Expectations

- **Portfolio fetch**: ~5-10 seconds
- **Single screenshot**: ~2-5 seconds per portfolio
- **Full screenshot batch** (100 portfolios): ~20-30 minutes
  - 10 portfolios per batch × 5 seconds each = ~50 seconds per batch
  - 30 seconds delay between batches
  - 10 batches × 80 seconds = ~13-15 minutes

Adjust `BATCH_SIZE` and `DELAY_SECONDS` based on your server resources.

