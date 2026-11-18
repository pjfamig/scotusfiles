import { Controller } from "@hotwired/stimulus"

// Comments are broadcast to everyone, so controls that only the author (or
// an admin) may use are revealed client-side, and authors can't vote on
// their own comments. The server still authorizes.
export default class extends Controller {
  static targets = [ "control", "vote" ]
  static values = { authorId: String }

  controlTargetConnected(control) {
    control.hidden = !(this.owner || this.admin)
  }

  voteTargetConnected(button) {
    button.disabled = this.owner
    if (this.owner) button.title = "You can’t vote on your own comment"
  }

  get owner() {
    const userId = document.querySelector('meta[name="current-user-id"]')?.content
    return Boolean(userId) && userId === this.authorIdValue
  }

  get admin() {
    return document.querySelector('meta[name="current-user-admin"]')?.content === "true"
  }
}
