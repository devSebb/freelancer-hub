import { Controller } from "@hotwired/stimulus"

// Handles the "show more" functionality for lists
// Initially shows 10 items, expands to show all 20 on first page
export default class extends Controller {
  static targets = ["item", "showMoreButton", "container"]
  static values = {
    initialLimit: { type: Number, default: 10 },
    expanded: { type: Boolean, default: false }
  }

  connect() {
    this.updateVisibility()
  }

  updateVisibility() {
    const items = this.itemTargets

    if (this.expandedValue) {
      // Show all items
      items.forEach(item => {
        item.classList.remove("hidden")
      })
      // Hide the show more button
      if (this.hasShowMoreButtonTarget) {
        this.showMoreButtonTarget.classList.add("hidden")
      }
    } else {
      // Show only first initialLimit items
      items.forEach((item, index) => {
        if (index < this.initialLimitValue) {
          item.classList.remove("hidden")
        } else {
          item.classList.add("hidden")
        }
      })
      // Show the button only if there are more items to show
      if (this.hasShowMoreButtonTarget) {
        if (items.length > this.initialLimitValue) {
          this.showMoreButtonTarget.classList.remove("hidden")
        } else {
          this.showMoreButtonTarget.classList.add("hidden")
        }
      }
    }
  }

  expand() {
    this.expandedValue = true
    this.updateVisibility()

    // Smooth scroll the container if needed
    if (this.hasContainerTarget) {
      this.containerTarget.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  expandedValueChanged() {
    this.updateVisibility()
  }
}
