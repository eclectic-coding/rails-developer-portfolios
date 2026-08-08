import { Controller } from "@hotwired/stimulus"

// Submits the attached search form on input, with a small debounce.
// The form targets the portfolios_cards Turbo Frame (data-turbo-frame),
// so results update in place without ever touching the browser URL.
// Also toggles a floating clear (X) button based on whether the field
// has a value, and clears the search back to the default state on click.
export default class extends Controller {
  static targets = ["input", "clear"]
  static values = {
    delay: { type: Number, default: 250 }
  }

  connect() {
    console.log("PortfolioSearchController connected")
    this.submit = this.submit.bind(this)
    this._timer = null
    this.toggleClear()
  }

  submit() {
    this.toggleClear()

    if (this._timer) clearTimeout(this._timer)

    this._timer = setTimeout(() => {
      this.requestSubmit()
    }, this.delayValue)
  }

  clear() {
    if (this._timer) clearTimeout(this._timer)

    this.inputTarget.value = ""
    this.toggleClear()
    this.inputTarget.focus()
    this.requestSubmit()
  }

  toggleClear() {
    if (!this.hasClearTarget || !this.hasInputTarget) return

    this.clearTarget.classList.toggle("d-none", this.inputTarget.value.length === 0)
  }

  requestSubmit() {
    const form = this.element
    if (form && typeof form.requestSubmit === "function") {
      form.requestSubmit()
    } else if (form) {
      form.submit()
    }
  }
}