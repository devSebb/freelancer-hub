import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "item", "destroy"]

  add(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  recalculate(event) {
    const item = event.target.closest("[data-invoice-items-target='item']")
    if (!item) return

    const quantityEl = item.querySelector("input[name*='[quantity]']")
    const rateEl = item.querySelector("input[name*='[rate]']")
    const amountEl = item.querySelector("[data-invoice-items-target='amount']")
    if (!quantityEl || !rateEl || !amountEl) return

    const quantity = this.parseDecimal(quantityEl.value)
    const rate = this.parseDecimal(rateEl.value)

    const amount = (quantity || 0) * (rate || 0)
    amountEl.textContent = this.replaceNumberInCurrency(amountEl.textContent, amount)
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

  parseDecimal(value) {
    if (value === null || value === undefined) return null
    let s = String(value).trim()
    if (!s) return null

    // Strip currency symbols/spaces; keep digits, separators, minus.
    s = s.replace(/[^\d.,-]/g, "")

    const lastDot = s.lastIndexOf(".")
    const lastComma = s.lastIndexOf(",")

    if (lastDot !== -1 && lastComma !== -1) {
      // Last separator is decimal separator; other is thousands separator.
      if (lastComma > lastDot) {
        s = s.replace(/\./g, "").replace(",", ".")
      } else {
        s = s.replace(/,/g, "")
      }
    } else if (lastComma !== -1 && lastDot === -1) {
      s = s.replace(",", ".")
    }

    const n = Number.parseFloat(s)
    return Number.isFinite(n) ? n : null
  }

  replaceNumberInCurrency(currentText, number) {
    const text = String(currentText || "").trim()
    const match = text.match(/-?[\d.,]+/)

    const formatted = Number.isFinite(number) ? number.toFixed(2) : "0.00"
    if (!match || match.index === undefined) return formatted

    const start = match.index
    const end = start + match[0].length
    const prefix = text.slice(0, start)
    const suffix = text.slice(end)

    return `${prefix}${formatted}${suffix}`.trim()
  }
}
