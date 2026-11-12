import { Controller } from "@hotwired/stimulus"

// Marks sentences that have comments. The element is re-rendered by Turbo
// Stream broadcasts whenever counts change, which reconnects this controller.
export default class extends Controller {
  static values = { counts: Object }

  connect() {
    document.querySelectorAll(".sentence.has-comments").forEach((sentence) => {
      sentence.classList.remove("has-comments")
      delete sentence.dataset.count
    })

    for (const [ key, count ] of Object.entries(this.countsValue)) {
      const sentence = document.getElementById(`s-${key}`)
      if (!sentence) continue

      sentence.classList.add("has-comments")
      sentence.dataset.count = count
      sentence.title = `${count} ${count === 1 ? "comment" : "comments"}`
    }
  }
}
