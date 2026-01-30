# Portfolio API Integration Examples

Here are practical examples for using the Developer Portfolios API in your application.

## 1. Basic Display in a View

### ERB Template
```erb
<!-- app/views/pages/portfolios.html.erb -->
<div class="container">
  <h1>Developer Portfolios</h1>

  <div id="portfolios-list" class="row">
    <% @portfolios.each do |portfolio| %>
      <div class="col-md-4 mb-3">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title"><%= portfolio['name'] %></h5>
            <% if portfolio['link'].present? %>
              <%= link_to 'View Portfolio', portfolio['link'],
                  class: 'btn btn-primary',
                  target: '_blank',
                  rel: 'noopener noreferrer' %>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

### Controller
```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def portfolios
    @portfolios = DeveloperPortfoliosFetcher.fetch
  end
end
```

## 2. Search and Filter Feature

### HTML with Stimulus
```html
<div data-controller="portfolio-search">
  <!-- Search Input -->
  <div class="mb-3">
    <input type="text"
           class="form-control"
           placeholder="Search portfolios..."
           data-portfolio-search-target="input"
           data-action="input->portfolio-search#filter">
  </div>

  <!-- Results Count -->
  <p class="text-muted">
    Showing <span data-portfolio-search-target="count">0</span> portfolios
  </p>

  <!-- Portfolios Container -->
  <div class="row" data-portfolio-search-target="container"></div>
</div>
```

### Stimulus Controller
```javascript
// app/javascript/controllers/portfolio_search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "count"]

  connect() {
    this.loadPortfolios()
  }

  async loadPortfolios() {
    const response = await fetch('/portfolios.json')
    this.allPortfolios = await response.json()
    this.displayPortfolios(this.allPortfolios)
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()

    const filtered = this.allPortfolios.filter(portfolio =>
      portfolio.name.toLowerCase().includes(query)
    )

    this.displayPortfolios(filtered)
  }

  displayPortfolios(portfolios) {
    this.countTarget.textContent = portfolios.length

    this.containerTarget.innerHTML = portfolios.map(p => `
      <div class="col-md-4 mb-3">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">${this.escape(p.name)}</h5>
            ${p.link ? `
              <a href="${this.escape(p.link)}"
                 class="btn btn-primary btn-sm"
                 target="_blank"
                 rel="noopener">
                View Portfolio
              </a>
            ` : ''}
          </div>
        </div>
      </div>
    `).join('')
  }

  escape(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
```

## 3. Random Portfolio Showcase

### HTML
```html
<div class="card" data-controller="random-portfolio">
  <div class="card-body">
    <h5 class="card-title">Featured Developer</h5>
    <div data-random-portfolio-target="content">
      Loading...
    </div>
    <button class="btn btn-secondary mt-3"
            data-action="click->random-portfolio#shuffle">
      Show Another
    </button>
  </div>
</div>
```

### Stimulus Controller
```javascript
// app/javascript/controllers/random_portfolio_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.loadPortfolios()
  }

  async loadPortfolios() {
    const response = await fetch('/portfolios.json')
    this.portfolios = await response.json()
    this.showRandom()
  }

  showRandom() {
    if (!this.portfolios || this.portfolios.length === 0) return

    const random = this.portfolios[
      Math.floor(Math.random() * this.portfolios.length)
    ]

    this.contentTarget.innerHTML = `
      <h4>${this.escape(random.name)}</h4>
      ${random.link ? `
        <a href="${this.escape(random.link)}"
           class="btn btn-primary"
           target="_blank">
          Visit Portfolio
        </a>
      ` : '<p class="text-muted">No link available</p>'}
    `
  }

  shuffle() {
    this.showRandom()
  }

  escape(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
```

## 4. Pagination Example

### Stimulus Controller with Pagination
```javascript
// app/javascript/controllers/paginated_portfolios_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "pageInfo"]
  static values = {
    perPage: { type: Number, default: 12 },
    currentPage: { type: Number, default: 1 }
  }

  connect() {
    this.loadPortfolios()
  }

  async loadPortfolios() {
    const response = await fetch('/portfolios.json')
    this.allPortfolios = await response.json()
    this.totalPages = Math.ceil(this.allPortfolios.length / this.perPageValue)
    this.showPage(this.currentPageValue)
  }

  showPage(page) {
    this.currentPageValue = page

    const start = (page - 1) * this.perPageValue
    const end = start + this.perPageValue
    const pagePortfolios = this.allPortfolios.slice(start, end)

    this.displayPortfolios(pagePortfolios)
    this.updatePageInfo()
  }

  nextPage() {
    if (this.currentPageValue < this.totalPages) {
      this.showPage(this.currentPageValue + 1)
    }
  }

  previousPage() {
    if (this.currentPageValue > 1) {
      this.showPage(this.currentPageValue - 1)
    }
  }

  displayPortfolios(portfolios) {
    this.containerTarget.innerHTML = portfolios.map(p => `
      <div class="col-md-4 mb-3">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">${this.escape(p.name)}</h5>
            ${p.link ? `
              <a href="${this.escape(p.link)}" target="_blank">
                View Portfolio
              </a>
            ` : ''}
          </div>
        </div>
      </div>
    `).join('')
  }

  updatePageInfo() {
    this.pageInfoTarget.textContent =
      `Page ${this.currentPageValue} of ${this.totalPages}`
  }

  escape(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
```

## 5. Using with Turbo Frames

### View with Turbo Frame
```erb
<!-- app/views/layouts/application.html.erb -->
<nav>
  <%= link_to "Portfolios", portfolios_path,
      data: { turbo_frame: "main_content" } %>
</nav>

<turbo-frame id="main_content">
  <%= yield %>
</turbo-frame>
```

```erb
<!-- app/views/portfolios/index.html.erb -->
<turbo-frame id="main_content">
  <h1>Developer Portfolios</h1>
  <div class="row">
    <% @portfolios.first(20).each do |portfolio| %>
      <div class="col-md-4">
        <%= portfolio['name'] %>
      </div>
    <% end %>
  </div>
</turbo-frame>
```

## 6. Background Refresh with Notifications

### Stimulus Controller with Toast Notifications
```javascript
// app/javascript/controllers/portfolio_refresh_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.checkForUpdates()
    // Check every hour
    this.interval = setInterval(() => this.checkForUpdates(), 3600000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  async checkForUpdates() {
    try {
      const response = await fetch('/portfolios.json')
      const portfolios = await response.json()

      const stored = localStorage.getItem('portfolios_count')
      if (stored && parseInt(stored) !== portfolios.length) {
        this.showNotification('New portfolios available!')
      }

      localStorage.setItem('portfolios_count', portfolios.length)
    } catch (error) {
      console.error('Failed to check for updates:', error)
    }
  }

  showNotification(message) {
    // Using Bootstrap toast (adjust for your toast implementation)
    const toast = `
      <div class="toast" role="alert">
        <div class="toast-body">
          ${message}
          <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
        </div>
      </div>
    `
    document.body.insertAdjacentHTML('beforeend', toast)
  }
}
```

## 7. Error Handling Example

```javascript
// app/javascript/controllers/robust_portfolios_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "loading", "error", "retry"]

  async connect() {
    this.loadPortfolios()
  }

  async loadPortfolios() {
    try {
      this.showLoading()

      const response = await fetch('/portfolios.json')

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const portfolios = await response.json()

      if (!Array.isArray(portfolios)) {
        throw new Error('Invalid data format received')
      }

      this.displayPortfolios(portfolios)
      this.hideLoading()
      this.hideError()

    } catch (error) {
      console.error('Error loading portfolios:', error)
      this.showError(error.message)
      this.hideLoading()
    }
  }

  retry() {
    this.loadPortfolios()
  }

  showLoading() {
    this.loadingTarget.classList.remove('d-none')
  }

  hideLoading() {
    this.loadingTarget.classList.add('d-none')
  }

  showError(message) {
    this.errorTarget.textContent = `Error: ${message}`
    this.errorTarget.classList.remove('d-none')
    this.retryTarget.classList.remove('d-none')
  }

  hideError() {
    this.errorTarget.classList.add('d-none')
    this.retryTarget.classList.add('d-none')
  }

  displayPortfolios(portfolios) {
    // Your display logic here
  }
}
```

## Tips for Production

1. **Add Loading States**: Always show loading indicators for better UX
2. **Handle Errors Gracefully**: Display user-friendly error messages
3. **Cache on Client Side**: Consider localStorage for frequently accessed data
4. **Optimize Rendering**: Use pagination for large datasets
5. **Monitor Performance**: Track API response times
6. **Add Analytics**: Track which portfolios get the most views

## Performance Optimization

```javascript
// Debounce search input
function debounce(func, wait) {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout)
      func(...args)
    }
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}

// Usage in controller
filter = debounce(this.filter.bind(this), 300)
```

---

For more information, see the [Quick Start Guide](./QUICK_START.md) or [API Documentation](./DEVELOPER_PORTFOLIOS_API.md).
