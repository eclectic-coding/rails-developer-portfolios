# Developer Portfolios

[![CI](https://github.com/eclectic-coding/rails-developer-portfolios/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/rails-developer-portfolios/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-4.0.5-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/rails-8.1-CC0000?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![codecov](https://codecov.io/gh/eclectic-coding/rails-developer-portfolios/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/rails-developer-portfolios)

A Rails application that fetches and displays developer portfolio data from GitHub.

## 🌟 Features

- **API Integration**: Fetches portfolio data from GitHub repository
- **Smart Caching**: 24-hour cache for optimal performance
- **Automatic Updates**: Weekly background job refreshes data every Monday at 2 AM
- **Multiple Formats**: JSON and HTML endpoints
- **Frontend Ready**: Includes Stimulus controller for easy integration
- **Fully Tested**: Comprehensive test coverage

## 🚀 Quick Start

### Fetch Portfolio Data

```bash
# Fetch and cache portfolio data
rails portfolios:fetch

# View cached data
rails portfolios:show

# Clear cache
rails portfolios:clear_cache
```

### Access the API

- **Root/Home**: `GET /` (displays all portfolios)
- **JSON API**: `GET /portfolios.json`
- **HTML View**: `GET /portfolios` (same as root)

### Use in JavaScript

```javascript
fetch('/portfolios.json')
  .then(response => response.json())
  .then(portfolios => {
    console.log(`Loaded ${portfolios.length} portfolios`);
  });
```

## 🔄 Manually Updating the Feed (Hatchbox)

The feed normally syncs automatically every Monday at 2 AM (see Configuration below). To force an update sooner — e.g. after deploying a fix, or to pull in newly added sites without waiting for the next scheduled run — SSH into Hatchbox and run one of:

```bash
# Sync the DB from the feed only (fast, no screenshots).
# New/updated/removed portfolios show up immediately after this.
bin/rails portfolios:fetch

# Sync the DB AND queue screenshot generation for every active portfolio
# (not just the new ones — this re-queues screenshots for the whole list,
# which can take a while: portfolios are batched 10 at a time, 30s apart).
bin/rails jobs:update_feed
```

To backfill a screenshot for one specific portfolio instead of the whole list:

```bash
bin/rails jobs:generate_screenshot[PORTFOLIO_ID]
```

Health checks, if something looks off:

```bash
bin/rails jobs:diagnostic          # full report: workers, queue, portfolios
bin/rails jobs:workers             # is a Solid Queue worker process actually running?
bin/rails jobs:status              # pending/failed job counts
bin/rails jobs:failed              # failed job details
bin/rails jobs:missing_screenshots # active portfolios without a screenshot
```

See [Jobs Cheatsheet](docs/JOBS_CHEATSHEET.md) for the full command reference.

> **Note:** A malformed or duplicate URL in the upstream feed no longer aborts the whole sync — invalid entries are now skipped and logged individually instead. See Configuration below for how sync results get emailed to the admin.

## 📚 Documentation

- [Deployment Jobs Checklist](docs/DEPLOYMENT_JOBS_CHECKLIST.md)
- [Deploy Commands](docs/DEPLOY_COMMANDS.md)
- [Jobs Reference](docs/JOBS_REFERENCE.md)
- [Jobs Cheatsheet](docs/JOBS_CHEATSHEET.md)

## 🧪 Testing

```bash
# Run all tests
bin/rspec

# Run specific tests
bin/rspec spec/services/developer_portfolios_fetcher_spec.rb
bin/rspec spec/requests/portfolios_spec.rb
```

## 📦 What's Included

- Service layer for API fetching (`app/services/`)
- Background job for automatic updates (`app/jobs/`)
- Controller with JSON/HTML support (`app/controllers/`)
- Stimulus controller for frontend (`app/javascript/controllers/`)
- Rake tasks for manual operations (`lib/tasks/`)
- Comprehensive test suite (`spec/`)

## ⚙️ Configuration

The recurring job is configured in `config/recurring.yml`:

```yaml
development:
  fetch_developer_portfolios:
    class: FetchDeveloperPortfoliosJob
    schedule: every Monday at 2am
```

Sync results are emailed to the admin after every run (scheduled or manual via `jobs:update_feed`). Configure the recipient with `bin/rails credentials:edit` (add `admin_email: you@example.com`), and set SMTP settings in `config/environments/production.rb` (commented out by default) for delivery to actually work in production.

## 🚢 Deployment

Deployed via [Hatchbox](https://hatchbox.io). See the [Deploy Commands](docs/DEPLOY_COMMANDS.md) and [Deployment Jobs Checklist](docs/DEPLOYMENT_JOBS_CHECKLIST.md) for post-deploy steps.

## 💾 Data Source

Fetches from: https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json

## ✅ Status

**Portfolios**: Developer portfolios loaded from upstream feed (count varies over time)
**Cache duration**: 24 hours
**Auto-refresh**: Weekly on Monday at 2 AM
**Tests**: See CI status or run locally with `bin/rspec`
