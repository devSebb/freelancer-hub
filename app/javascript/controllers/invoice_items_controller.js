import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "item", "destroy"]

  add(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()

    const item = event.target.closest("[data-invoice-items-target='item']")
    if (!item) return

    // If this is a new record (no id), just remove it
    const destroyField = item.querySelector("[data-invoice-items-target='destroy']")
    if (destroyField) {
      // Check if this is a persisted record by looking for an id field
      const idField = item.querySelector("input[name*='[id]']")
      if (idField && idField.value) {
        // Mark for destruction
        destroyField.value = "1"
        item.style.display = "none"
      } else {
        // Remove from DOM
        item.remove()
      }
    } else {
      item.remove()
    }
  }
}
