import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyOnly", "yearlyOnly", "intervalInput", "toggleMonthly", "toggleYearly"]
  static values = { initialInterval: String }

  connect() {
    const initial = this.initialIntervalValue === "yearly" ? "yearly" : "monthly"
    this.setInterval(initial)
  }

  setMonthly(event) {
    event?.preventDefault()
    this.setInterval("monthly")
  }

  setYearly(event) {
    event?.preventDefault()
    this.setInterval("yearly")
  }

  setInterval(interval) {
    const yearly = interval === "yearly"

    this.monthlyOnlyTargets.forEach((el) => el.classList.toggle("hidden", yearly))
    this.yearlyOnlyTargets.forEach((el) => el.classList.toggle("hidden", !yearly))
    this.intervalInputTargets.forEach((el) => {
      el.value = interval
    })

    this.toggleMonthlyTarget.classList.toggle("bg-white", !yearly)
    this.toggleMonthlyTarget.classList.toggle("text-black", !yearly)
    this.toggleMonthlyTarget.classList.toggle("text-white/60", yearly)

    this.toggleYearlyTarget.classList.toggle("bg-white", yearly)
    this.toggleYearlyTarget.classList.toggle("text-black", yearly)
    this.toggleYearlyTarget.classList.toggle("text-white/60", !yearly)
  }
}
