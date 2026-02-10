import { Controller } from "@hotwired/stimulus"

// Manages dynamic payment methods for invoices
export default class extends Controller {
  static targets = ["container", "emptyState", "methodList", "iconsTemplate"]
  static values = {
    methods: { type: Array, default: [] }
  }

  connect() {
    this.renderMethods()
  }

  add(event) {
    event.preventDefault()
    const type = event.currentTarget.dataset.type || "other"

    const newMethod = {
      id: Date.now(),
      type: type,
      label: this.getDefaultLabel(type),
      ...this.getDefaultFields(type)
    }

    this.methodsValue = [...this.methodsValue, newMethod]
    this.renderMethods()
  }

  remove(event) {
    event.preventDefault()
    const id = parseInt(event.currentTarget.dataset.id)
    this.methodsValue = this.methodsValue.filter(m => m.id !== id)
    this.renderMethods()
  }

  updateField(event) {
    const id = parseInt(event.currentTarget.dataset.id)
    const field = event.currentTarget.dataset.field
    const value = event.currentTarget.value

    this.methodsValue = this.methodsValue.map(m => {
      if (m.id === id) {
        return { ...m, [field]: value }
      }
      return m
    })
  }

  getDefaultLabel(type) {
    const labels = {
      bank_transfer: "Bank Transfer",
      paypal: "PayPal",
      venmo: "Venmo",
      zelle: "Zelle",
      cashapp: "Cash App",
      crypto: "Cryptocurrency",
      other: "Other"
    }
    return labels[type] || "Payment Method"
  }

  getDefaultFields(type) {
    switch(type) {
      case "bank_transfer":
        return { bank_name: "", account_number: "", routing_number: "" }
      case "paypal":
      case "zelle":
        return { email: "" }
      case "venmo":
      case "cashapp":
        return { handle: "" }
      case "crypto":
        return { address: "", instructions: "" }
      default:
        return { instructions: "" }
    }
  }

  getIconFor(key) {
    if (!this.hasIconsTemplateTarget) return ""
    const node = this.iconsTemplateTarget.content.querySelector(`[data-icon="${key}"]`)
    return node ? node.innerHTML.trim() : ""
  }

  renderMethods() {
    if (!this.hasMethodListTarget) return

    // Show/hide empty state
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.toggle("hidden", this.methodsValue.length > 0)
    }

    // Clear existing methods
    this.methodListTarget.innerHTML = ""

    // Render each method
    this.methodsValue.forEach((method, index) => {
      const html = this.renderMethodCard(method, index)
      this.methodListTarget.insertAdjacentHTML("beforeend", html)
    })
  }

  renderMethodCard(method, index) {
    const icon = this.getIconFor(method.type) || this.getIconFor("other")
    const fields = this.renderFields(method, index)

    return `
      <div class="bg-white/5 border border-white/10 rounded-xl p-4" data-method-id="${method.id}">
        <div class="flex items-start justify-between mb-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center text-white/60">
              ${icon}
            </div>
            <input type="text"
                   value="${method.label || ''}"
                   data-id="${method.id}"
                   data-field="label"
                   data-action="change->payment-methods#updateField"
                   name="invoice[payment_methods][${index}][label]"
                   class="bg-transparent border-none text-white font-medium text-sm focus:outline-none focus:ring-0 p-0"
                   placeholder="Label">
            <input type="hidden" name="invoice[payment_methods][${index}][type]" value="${method.type}">
          </div>
          <button type="button"
                  data-id="${method.id}"
                  data-action="payment-methods#remove"
                  class="p-1.5 text-white/40 hover:text-red-400 transition-colors"
                  aria-label="Remove payment method">
            ${this.getIconFor("remove")}
          </button>
        </div>
        <div class="space-y-3">
          ${fields}
        </div>
      </div>
    `
  }

  renderFields(method, index) {
    const inputClass = "w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm placeholder-white/30 focus:outline-none focus:border-white/30 transition-colors"

    switch(method.type) {
      case "bank_transfer":
        return `
          <div>
            <label class="block text-xs text-white/50 mb-1">Bank Name</label>
            <input type="text" name="invoice[payment_methods][${index}][bank_name]" value="${method.bank_name || ''}"
                   data-id="${method.id}" data-field="bank_name" data-action="change->payment-methods#updateField"
                   class="${inputClass}" placeholder="e.g., Chase, Bank of America">
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs text-white/50 mb-1">Account Number</label>
              <input type="text" name="invoice[payment_methods][${index}][account_number]" value="${method.account_number || ''}"
                     data-id="${method.id}" data-field="account_number" data-action="change->payment-methods#updateField"
                     class="${inputClass}" placeholder="****1234">
            </div>
            <div>
              <label class="block text-xs text-white/50 mb-1">Routing Number</label>
              <input type="text" name="invoice[payment_methods][${index}][routing_number]" value="${method.routing_number || ''}"
                     data-id="${method.id}" data-field="routing_number" data-action="change->payment-methods#updateField"
                     class="${inputClass}" placeholder="021000021">
            </div>
          </div>
        `
      case "paypal":
      case "zelle":
        return `
          <div>
            <label class="block text-xs text-white/50 mb-1">Email Address</label>
            <input type="email" name="invoice[payment_methods][${index}][email]" value="${method.email || ''}"
                   data-id="${method.id}" data-field="email" data-action="change->payment-methods#updateField"
                   class="${inputClass}" placeholder="you@example.com">
          </div>
        `
      case "venmo":
      case "cashapp":
        return `
          <div>
            <label class="block text-xs text-white/50 mb-1">Handle</label>
            <input type="text" name="invoice[payment_methods][${index}][handle]" value="${method.handle || ''}"
                   data-id="${method.id}" data-field="handle" data-action="change->payment-methods#updateField"
                   class="${inputClass}" placeholder="@username">
          </div>
        `
      case "crypto":
        return `
          <div>
            <label class="block text-xs text-white/50 mb-1">Wallet Address</label>
            <input type="text" name="invoice[payment_methods][${index}][address]" value="${method.address || ''}"
                   data-id="${method.id}" data-field="address" data-action="change->payment-methods#updateField"
                   class="${inputClass}" placeholder="0x... or bc1...">
          </div>
          <div>
            <label class="block text-xs text-white/50 mb-1">Instructions (currency, network, etc.)</label>
            <input type="text" name="invoice[payment_methods][${index}][instructions]" value="${method.instructions || ''}"
                   data-id="${method.id}" data-field="instructions" data-action="change->payment-methods#updateField"
                   class="${inputClass}" placeholder="e.g., Bitcoin (BTC) - Mainnet only">
          </div>
        `
      default:
        return `
          <div>
            <label class="block text-xs text-white/50 mb-1">Payment Instructions</label>
            <textarea name="invoice[payment_methods][${index}][instructions]"
                      data-id="${method.id}" data-field="instructions" data-action="change->payment-methods#updateField"
                      class="${inputClass} resize-none" rows="2"
                      placeholder="Enter payment instructions...">${method.instructions || ''}</textarea>
          </div>
        `
    }
  }

  methodsValueChanged() {
    this.renderMethods()
  }
}
