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
    schedule: every week on Monday at 2am
```

## 🚢 Deployment

Deployed via [Hatchbox](https://hatchbox.io). See the [Deploy Commands](docs/DEPLOY_COMMANDS.md) and [Deployment Jobs Checklist](docs/DEPLOYMENT_JOBS_CHECKLIST.md) for post-deploy steps.

## 💾 Data Source

Fetches from: https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json

## ✅ Status

**Portfolios**: Developer portfolios loaded from upstream feed (count varies over time)
**Cache duration**: 24 hours
**Auto-refresh**: Weekly on Monday at 2 AM
**Tests**: See CI status or run locally with `bin/rspec`
