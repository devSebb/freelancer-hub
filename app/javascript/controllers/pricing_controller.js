import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "fixed", "hourly"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isHourly = this.typeTarget.value === "hourly"

    this.fixedTarget.classList.toggle("hidden", isHourly)
    this.hourlyTarget.classList.toggle("hidden", !isHourly)
  }
}
