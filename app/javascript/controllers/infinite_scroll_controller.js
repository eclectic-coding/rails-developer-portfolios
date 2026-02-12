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
    console.log("InfiniteScrollController connected")
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
    console.log("Sentinel target connected, reconnecting observer")
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

    if (!this.hasSentinelTarget) {
      console.log("No sentinel target found, skipping observer creation")
      return
    }

    const nextUrl = this.getNextPageUrl()
    console.log("Creating observer with next URL:", nextUrl)

    if (!nextUrl) {
      console.log("No next page URL, stopping")
      return
    }

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
            console.log("Sentinel is intersecting, loading more...")
            this.loadMore(url)
          }
        }
      })
    }, options)

    this.observer.observe(this.sentinelTarget)
    console.log("Observer created and watching sentinel")
  }

  getNextPageUrl() {
    const container = document.getElementById('sentinel-container')
    if (!container) {
      console.log("Sentinel container not found")
      return null
    }

    const url = container.dataset.nextPageUrl
    console.log("Next page URL from data attribute:", url)
    return url || null
  }

  async loadMore(url) {
    if (this.loading || !url) {
      console.log("Skipping load - loading:", this.loading, "url:", url)
      return
    }

    this.loading = true
    console.log("→ Fetching:", url)

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
      console.log("✓ Received turbo stream response, rendering...")

      // Use Turbo to process the stream
      if (window.Turbo) {
        Turbo.renderStreamMessage(html)
      }

      console.log("✓ Rendering complete")
    } catch (error) {
      console.error("✗ Error loading more portfolios:", error)
    } finally {
      this.loading = false
      console.log("✓ Load complete, ready for next page")
    }
  }
}

