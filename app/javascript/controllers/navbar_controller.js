import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  connect() {
    console.log("Navbar connected!")
  }

  toggleMenu() {
    console.log('aaa')
    this.menuTarget.classList.toggle("hidden")
    this.menuTarget.classList.toggle("translate-x-full")
  }
}