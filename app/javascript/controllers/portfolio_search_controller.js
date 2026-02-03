import { Controller } from "@hotwired/stimulus"

// Submits the attached search form on input, with a small debounce,
// targeting the Turbo frame defined on the form (data-turbo-frame)
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 250 }
  }

  connect() {
    console.log("PortfolioSearchController connected")
    this.submit = this.submit.bind(this)
    this._timer = null
  }

  submit() {
    if (this._timer) clearTimeout(this._timer)

    this._timer = setTimeout(() => {
      const form = this.element
      if (form && typeof form.requestSubmit === "function") {
        form.requestSubmit()
      } else if (form) {
        form.submit()
      }
    }, this.delayValue)
  }
}

