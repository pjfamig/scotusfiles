import { Controller } from "@hotwired/stimulus"

// Applies the chosen highlight color immediately; the swatch's form then saves
// it to the reader's account and the picker is replaced via Turbo Stream.
export default class extends Controller {
  preview({ params: { color } }) {
    document.documentElement.dataset.highlight = color
  }

  close() {
    this.element.open = false
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
