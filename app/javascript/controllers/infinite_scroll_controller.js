import { Controller } from "@hotwired/stimulus"

/**
 * Infinite scroll controller using Intersection Observer API
 * Loads more content when the sentinel element comes into view
 *
 * Usage:
 *   <div data-controller="infinite-scroll"
 *        data-infinite-scroll-url-value="/portfolios?page=2">
 *     <!-- content -->
 *     <div data-infinite-scroll-target="sentinel"></div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["sentinel", "entries"]
  static values = {
    url: String
  }

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

  createObserver() {
    if (!this.hasSentinelTarget) {
      console.log("No sentinel target found")
      return
    }

    const options = {
      root: null, // viewport
      rootMargin: "100px", // Start loading 100px before the sentinel is visible
      threshold: 0.1
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.loading && this.hasUrlValue) {
          this.loadMore()
        }
      })
    }, options)

    this.observer.observe(this.sentinelTarget)
  }

  async loadMore() {
    if (this.loading || !this.hasUrlValue) return

    this.loading = true
    console.log("Loading more portfolios from:", this.urlValue)

    try {
      const response = await fetch(this.urlValue, {
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

  // Called when the URL value changes (e.g., after loading a page)
  urlValueChanged() {
    console.log("URL changed to:", this.urlValue)

    // If URL is empty or null, we've reached the end
    if (!this.urlValue || this.urlValue === "" || this.urlValue === "null") {
      console.log("No more pages to load")
      if (this.observer && this.hasSentinelTarget) {
        this.observer.unobserve(this.sentinelTarget)
      }
    }
  }
}

