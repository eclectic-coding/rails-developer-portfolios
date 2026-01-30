# Developer Portfolios

A Rails application that fetches and displays developer portfolio data from GitHub.

## 🌟 Features

- **API Integration**: Fetches portfolio data from GitHub repository
- **Smart Caching**: 24-hour cache for optimal performance
- **Automatic Updates**: Daily background job refreshes data at 2 AM
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

- [Quick Start Guide](docs/QUICK_START.md) - Get started quickly
- [API Documentation](docs/DEVELOPER_PORTFOLIOS_API.md) - Full API reference
- [Setup Summary](docs/SETUP_SUMMARY.md) - Implementation details

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
    schedule: every day at 2am
```

## 💾 Data Source

Fetches from: https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json

## ✅ Status

**Portfolios**: Developer portfolios loaded from upstream feed (count varies over time)
**Cache duration**: 24 hours
**Auto-refresh**: Daily at 2 AM
**Tests**: See CI status or run locally with `bin/rspec`
