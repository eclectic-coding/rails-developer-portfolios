# Developer Portfolios API Integration

This application fetches developer portfolio data from the GitHub repository and persists it in the local `portfolios` database table.

## Overview

The system includes:
- **Service**: `DeveloperPortfoliosFetcher` - Fetches data from the remote feed and syncs it into the DB
- **Job**: `FetchDeveloperPortfoliosJob` - Background job to refresh the local data
- **Model**: `Portfolio` - ActiveRecord model backed by the `portfolios` table
- **Controller**: `PortfoliosController` - Serves data from the DB to the frontend

The data is refreshed on a schedule (see `config/recurring.yml`) and can also be triggered manually.

## API Endpoint

### Get Portfolios
- **URL**: `/portfolios`
- **Method**: GET
- **Formats**: JSON, HTML

#### JSON Response

```http
GET /portfolios.json
```

Returns an array of portfolio objects coming from the `portfolios` table. Example shape:

```json
[
  {
    "name": "Developer Name",
    "path": "https://portfolio-url.com",
    "tagline": "Optional tagline or expertise",
    "active": true
  },
  {
    "name": "Another Developer",
    "path": "https://another-portfolio.com",
    "tagline": null,
    "active": true
  }
]
```

> Note: The source feed uses a `url` field; this is stored in the `path` column on the `portfolios` table and exposed as `path` in the JSON response.

#### HTML View

```http
GET /portfolios
```

Returns a rendered HTML page with all active portfolios.

## Usage Examples

### From JavaScript (Frontend)
```javascript
// Fetch portfolios as JSON
fetch('/portfolios.json')
  .then(response => response.json())
  .then(data => {
    console.log('Portfolios:', data)
    // Use the data in your frontend
  })
  .catch(error => console.error('Error:', error))
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

### Sync Data Manually (Rails Console)
```ruby
# Fetch from remote feed and sync into the DB
DeveloperPortfoliosFetcher.fetch_and_sync

# Inspect portfolios from the DB
Portfolio.active
```

### Run Job Manually
```ruby
# In Rails console
FetchDeveloperPortfoliosJob.perform_now

# Or enqueue for background processing
FetchDeveloperPortfoliosJob.perform_later
```

## Automatic Refresh

The data is automatically refreshed on a schedule via a recurring job configured in `config/recurring.yml`.

## Source Data

The data is fetched from:

```
https://raw.githubusercontent.com/emmabostian/developer-portfolios/master/feed.json
```

## Error Handling

The service includes basic error handling:
- Logs HTTP and parsing errors to the Rails logger
- Returns `false` from `fetch_and_sync` if the remote fetch fails
- Leaves existing DB data untouched if a sync attempt fails
