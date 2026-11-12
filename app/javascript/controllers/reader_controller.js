import { Controller } from "@hotwired/stimulus"

// Click a sentence to load its discussion into the margin panel (a bottom
// sheet on small screens). The selected sentence is reflected in the URL hash
// so passages can be linked to directly.
export default class extends Controller {
  static targets = [ "panel", "frame" ]
  static values = { passageUrl: String, discussionUrl: String }

  connect() {
    const key = this.#keyFromLocation()
    if (key) requestAnimationFrame(() => this.#open(key, { scroll: true }))
  }

  select(event) {
    if (event.target.closest("a, button, input, textarea")) return
    if (window.getSelection()?.toString().trim()) return

    const sentence = event.target.closest(".sentence")
    if (!sentence) return

    if (sentence.classList.contains("is-selected")) {
      this.close()
    } else {
      this.#open(sentence.dataset.key)
    }
  }

  jump({ params: { key } }) {
    this.#open(key, { scroll: true })
  }

  close() {
    if (!this.#selected) return

    this.#selected.classList.remove("is-selected")
    this.frameTarget.src = this.discussionUrlValue
    this.panelTarget.removeAttribute("data-open")
    history.replaceState(history.state, "", location.pathname)
  }

  #open(key, { scroll = false } = {}) {
    const sentence = document.getElementById(`s-${key}`)
    if (!sentence) return

    this.#selected?.classList.remove("is-selected")
    sentence.classList.add("is-selected")
    if (scroll) sentence.scrollIntoView({ behavior: "smooth", block: "center" })

    this.frameTarget.src = this.passageUrlValue.replace("__KEY__", encodeURIComponent(key))
    this.panelTarget.setAttribute("data-open", "")
    history.replaceState(history.state, "", `${location.pathname}#s-${key}`)
  }

  // Turbo drops URL fragments when following redirects, so links that
  // survive a sign-in redirect carry the passage as ?s=KEY instead.
  #keyFromLocation() {
    const match = location.hash.match(/^#s-(.+)$/)
    return match ? decodeURIComponent(match[1]) : new URLSearchParams(location.search).get("s")
  }

  get #selected() {
    return this.element.querySelector(".sentence.is-selected")
  }
}
