import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="portfolios"
export default class extends Controller {
  static targets = ["container", "loading", "error"]

  connect() {
    this.loadPortfolios()
  }

  async loadPortfolios() {
    try {
      this.showLoading()
      const response = await fetch('/portfolios.json')

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const portfolios = await response.json()
      this.displayPortfolios(portfolios)
      this.hideLoading()
    } catch (error) {
      console.error('Error loading portfolios:', error)
      this.showError(error.message)
    }
  }

  displayPortfolios(portfolios) {
    if (!this.hasContainerTarget) return

    const html = portfolios.map(portfolio => `
      <div class="col-md-6 col-lg-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <h5 class="card-title">${this.escapeHtml(portfolio.name || 'Unknown')}</h5>
            ${portfolio.link ? `
              <a href="${this.escapeHtml(portfolio.link)}"
                 class="btn btn-primary btn-sm"
                 target="_blank"
                 rel="noopener noreferrer">
                View Portfolio
              </a>
            ` : ''}
          </div>
        </div>
      </div>
    `).join('')

    this.containerTarget.innerHTML = html
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('d-none')
    }
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add('d-none')
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('d-none')
    }
  }

  showError(message) {
    this.hideLoading()
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = `Error loading portfolios: ${message}`
      this.errorTarget.classList.remove('d-none')
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  async refresh() {
    await this.loadPortfolios()
  }
}
