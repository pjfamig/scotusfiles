import { Controller } from "@hotwired/stimulus"

// Comments are broadcast to everyone, so controls that only the author (or
// an admin) may use are revealed client-side. The server still authorizes.
export default class extends Controller {
  static targets = [ "control" ]
  static values = { authorId: String }

  connect() {
    const userId = document.querySelector('meta[name="current-user-id"]')?.content
    const admin = document.querySelector('meta[name="current-user-admin"]')?.content === "true"
    const owner = userId && userId === this.authorIdValue

    this.controlTargets.forEach((control) => control.hidden = !(owner || admin))
  }
}
