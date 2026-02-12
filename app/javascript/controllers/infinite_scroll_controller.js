import { Controller } from "@hotwired/stimulus"

/**
 * Infinite scroll controller using Intersection Observer API
 * Reads next page URL from sentinel-container's data-next-page-url attribute
 *
 * Usage:
 *   <div data-controller="infinite-scroll">
 *     <div id="sentinel-container" data-next-page-url="/portfolios?page=2">
 *       <div data-infinite-scroll-target="sentinel"></div>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["sentinel"]

  connect() {
    this.loading = false
    this.observer = null
    this.createObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  // Called when sentinel target is added/changed
  sentinelTargetConnected() {
    // Small delay to ensure DOM is fully updated
    setTimeout(() => {
      this.createObserver()
    }, 50)
  }

  createObserver() {
    // Disconnect existing observer
    if (this.observer) {
      this.observer.disconnect()
    }

    if (!this.hasSentinelTarget) return

    const nextUrl = this.getNextPageUrl()
    if (!nextUrl) return

    const options = {
      root: null, // viewport
      rootMargin: "200px", // Start loading 200px before the sentinel is visible
      threshold: 0.1
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.loading) {
          const url = this.getNextPageUrl()
          if (url) {
            this.loadMore(url)
          }
        }
      })
    }, options)

    this.observer.observe(this.sentinelTarget)
  }

  getNextPageUrl() {
    const container = document.getElementById('sentinel-container')
    if (!container) return null

    return container.dataset.nextPageUrl || null
  }

  async loadMore(url) {
    if (this.loading || !url) return

    this.loading = true

    try {
      const response = await fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const html = await response.text()

      // Use Turbo to process the stream
      if (window.Turbo) {
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Error loading more portfolios:", error)
    } finally {
      this.loading = false
    }
  }
}

