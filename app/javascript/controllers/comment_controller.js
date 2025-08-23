import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyForm"]
  connect(){
    console.log("replyFormActivated")
  }
  async showReplyForm(event) {
    const commentId = event.target.dataset.commentId;
    const formContainer = this.element.querySelector(`#reply-form-${commentId}`);
    if (formContainer) {
      formContainer.remove();
      return;
    }

    try {
      const response = await fetch(`/comments/new_reply?parent_id=${commentId}`);
      if (!response.ok) {
        throw new Error('Failed to fetch reply form.');
      }
      const html = await response.text();
      this.element.insertAdjacentHTML('beforeend', html);
    } catch (error) {
      console.error("Error showing reply form:", error);
    }
  }
}