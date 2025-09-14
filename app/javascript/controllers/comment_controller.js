import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyFormContainer"]
  static values = {
    unattachedBlobs: Array,
    imagesAllowed: { type: Boolean, default: true }
  };

  connect () {
  }

  toggleReply() {
    this.replyFormContainerTarget.classList.toggle("hidden")
  }
}