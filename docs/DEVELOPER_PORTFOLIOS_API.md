# Developer Portfolios API Integration

This application fetches and caches developer portfolio data from the GitHub repository.

## Overview

The system includes:
- **Service**: `DeveloperPortfoliosFetcher` - Fetches and caches data from the API
- **Job**: `FetchDeveloperPortfoliosJob` - Background job to refresh the cache
- **Controller**: `PortfoliosController` - Serves the data to the frontend
- **Cache**: 24-hour cache duration using Rails cache

## API Endpoint

### Get Portfolios
- **URL**: `/portfolios`
- **Method**: GET
- **Formats**: JSON, HTML

#### JSON Response
```
GET /portfolios.json
```

Returns an array of portfolio objects.

#### HTML View
```
GET /portfolios
```

Returns a rendered HTML page with all portfolios.

## Usage Examples

### From JavaScript (Frontend)
```javascript
// Fetch portfolios as JSON
fetch('/portfolios.json')
  .then(response => response.json())
  .then(data => {
    console.log('Portfolios:', data);
    // Use the data in your frontend
  })
  .catch(error => console.error('Error:', error));
```

### From Stimulus Controller
```javascript
// app/javascript/controllers/portfolios_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.loadPortfolios()
  }

  async loadPortfolios() {
    try {
      const response = await fetch('/portfolios.json')
      const portfolios = await response.json()
      this.displayPortfolios(portfolios)
    } catch (error) {
      console.error('Error loading portfolios:', error)
    }
  }

  displayPortfolios(portfolios) {
    // Your display logic here
  }
}
```

## Manual Operations

### Fetch Data Manually (Rails Console)
```ruby
# Fetch and cache data
DeveloperPortfoliosFetcher.fetch_and_cache

# Get cached data
data = DeveloperPortfoliosFetcher.fetch

# Clear cache
DeveloperPortfoliosFetcher.clear_cache
```

### Run Job Manually
```ruby
# In Rails console
FetchDeveloperPortfoliosJob.perform_now

# Or enqueue for background processing
FetchDeveloperPortfoliosJob.perform_later
```

## Automatic Refresh

The data is automatically refreshed daily at 2 AM via a recurring job configured in `config/recurring.yml`.

## Cache Details

- **Cache Key**: `developer_portfolios_data`
- **Duration**: 1 day (24 hours)
- **Backend**: Solid Cache (configured in the application)
- **Fallback**: Returns empty array if fetch fails and no cache exists

## Source Data

The data is fetched from:
```
https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json
```

## Error Handling

The service includes error handling:
- Returns cached data even if expired when fresh fetch fails
- Logs all errors to Rails logger
- Returns empty array as last resort fallback
