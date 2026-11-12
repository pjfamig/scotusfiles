import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "body" ]

  connect() {
    if (window.matchMedia("(min-width: 1024px)").matches) this.bodyTarget.focus({ preventScroll: true })
  }

  submit(event) {
    event.preventDefault()
    this.element.requestSubmit()
  }
}
