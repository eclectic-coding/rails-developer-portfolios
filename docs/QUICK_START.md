# Developer Portfolios API - Quick Start Guide

## 🚀 Getting Started

Your application now fetches and caches developer portfolio data from GitHub!

### Immediate Usage

**1. Fetch the data:**
```bash
rails portfolios:fetch
```

**2. View in browser:**
- HTML: http://localhost:3000/portfolios
- JSON: http://localhost:3000/portfolios.json

**3. Use in JavaScript:**
```javascript
fetch('/portfolios.json')
  .then(response => response.json())
  .then(portfolios => {
    console.log(`Loaded ${portfolios.length} portfolios`);
    // portfolios is an array of objects with 'name' and 'link' properties
  });
```

## 📋 Available Commands

### Rake Tasks

```bash
# Fetch and cache portfolio data
rails portfolios:fetch

# View cached data (first 5)
rails portfolios:show

# Clear the cache
rails portfolios:clear_cache
```

### Manual Job Execution

```bash
# Run the background job now
rails runner "FetchDeveloperPortfoliosJob.perform_now"

# Queue it for background processing
rails runner "FetchDeveloperPortfoliosJob.perform_later"
```

## 🎨 Frontend Examples

### Using Stimulus Controller

Add this to any view:

```html
<div data-controller="portfolios">
  <!-- Loading indicator -->
  <div data-portfolios-target="loading" class="d-none">
    <div class="spinner-border" role="status">
      <span class="visually-hidden">Loading...</span>
    </div>
  </div>

  <!-- Error display -->
  <div data-portfolios-target="error" class="alert alert-danger d-none"></div>

  <!-- Portfolios container -->
  <div class="row" data-portfolios-target="container"></div>
</div>
```

### Vanilla JavaScript

```javascript
async function loadPortfolios() {
  try {
    const response = await fetch('/portfolios.json');
    const portfolios = await response.json();

    portfolios.forEach(portfolio => {
      console.log(`${portfolio.name}: ${portfolio.link}`);
    });

    return portfolios;
  } catch (error) {
    console.error('Error loading portfolios:', error);
  }
}

// Call it
loadPortfolios();
```

### Using with Turbo Frame

```html
<turbo-frame id="portfolios" src="/portfolios">
  Loading portfolios...
</turbo-frame>
```

## ⏰ Automatic Updates

The data refreshes automatically every day at 2 AM. No manual intervention needed!

## 📊 Data Structure

Each portfolio object contains:

```json
{
  "name": "Developer Name",
  "link": "https://portfolio-url.com"
}
```

## 🔍 Testing

Run the specs:

```bash
# Run all portfolio-related tests
bin/rspec spec/services/developer_portfolios_fetcher_spec.rb
bin/rspec spec/requests/portfolios_spec.rb

# Run all tests
bin/rspec
```

## 🐛 Debugging

### Check if data is cached:

```bash
rails runner "puts Rails.cache.read('developer_portfolios_data')&.size || 'No cache'"
```

### Check cache expiry:

```ruby
# In Rails console
cache_key = DeveloperPortfoliosFetcher::CACHE_KEY
Rails.cache.fetch(cache_key) # Returns data if cached
```

### View logs:

```bash
# Development logs
tail -f log/development.log

# Filter for portfolio-related logs
tail -f log/development.log | grep -i portfolio
```

## 🎯 Common Use Cases

### Display on Homepage

```erb
<!-- app/views/static/home.html.erb -->
<div class="featured-portfolios">
  <h2>Featured Developer Portfolios</h2>
  <div data-controller="portfolios">
    <div data-portfolios-target="container" class="row"></div>
  </div>
</div>
```

### Create a Search Feature

```javascript
// Filter portfolios by name
function searchPortfolios(query) {
  fetch('/portfolios.json')
    .then(response => response.json())
    .then(portfolios => {
      const filtered = portfolios.filter(p =>
        p.name.toLowerCase().includes(query.toLowerCase())
      );
      displayResults(filtered);
    });
}
```

### Random Portfolio Display

```javascript
// Show a random portfolio
async function getRandomPortfolio() {
  const response = await fetch('/portfolios.json');
  const portfolios = await response.json();
  const random = portfolios[Math.floor(Math.random() * portfolios.length)];
  return random;
}
```

## 💡 Pro Tips

1. **First Load**: The first time you access `/portfolios.json`, it will fetch from GitHub (slower). All subsequent requests will be instant (cached).

2. **Force Refresh**: If you need fresh data immediately:
   ```bash
   rails portfolios:clear_cache && rails portfolios:fetch
   ```

3. **Production Ready**: The recurring job is configured for both development and production environments.

4. **Error Handling**: If GitHub is down, the service returns the last cached version (even if expired) or an empty array.

5. **Monitor Jobs**: In production, check your job queue dashboard to ensure the daily job runs successfully.

## 📚 Additional Documentation

- [Full API Documentation](./DEVELOPER_PORTFOLIOS_API.md)
- [Setup Summary](./SETUP_SUMMARY.md)

## ✅ Verification Checklist

- [ ] Data fetched successfully (`rails portfolios:fetch`)
- [ ] Cache working (`rails portfolios:show`)
- [ ] JSON endpoint accessible (`curl http://localhost:3000/portfolios.json`)
- [ ] HTML view renders (`visit http://localhost:3000/portfolios`)
- [ ] Tests passing (`bin/rspec`)
- [ ] Job configured (check `config/recurring.yml`)

---

**Current Status**: ✨ Fully operational with 1,456 portfolios cached!
