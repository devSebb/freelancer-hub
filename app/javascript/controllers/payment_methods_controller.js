import { Controller } from "@hotwired/stimulus"

// Manages dynamic payment methods for invoices
export default class extends Controller {
  static targets = ["container", "template", "emptyState", "methodList"]
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

  getTypeIcon(type) {
    const icons = {
      bank_transfer: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6m-1.5 12V10.332A48.36 48.36 0 0012 9.75c-2.551 0-5.056.2-7.5.582V21M3 21h18M12 6.75h.008v.008H12V6.75z"/>
      </svg>`,
      paypal: `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M7.076 21.337H2.47a.641.641 0 0 1-.633-.74L4.944.901C5.026.382 5.474 0 5.998 0h7.46c2.57 0 4.578.543 5.69 1.81 1.01 1.15 1.304 2.42 1.012 4.287-.023.143-.047.288-.077.437-.983 5.05-4.349 6.797-8.647 6.797h-2.19c-.524 0-.968.382-1.05.9l-1.12 7.106z"/>
      </svg>`,
      venmo: `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M19.5 3c.907 1.416 1.313 2.875 1.313 4.688 0 5.22-4.453 12-8.062 16.312H5.25L2.438 4.5l6.187-.563 1.5 12c1.407-2.25 3.188-5.813 3.188-8.25 0-1.688-.375-2.813-.938-3.75L19.5 3z"/>
      </svg>`,
      zelle: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z"/>
      </svg>`,
      cashapp: `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm3.248 7.002l-.623.755a.488.488 0 01-.632.107 3.72 3.72 0 00-1.86-.503c-.957 0-1.598.382-1.598.921 0 .571.586.762 1.546.948 1.757.34 3.284.918 3.284 2.773 0 1.572-1.18 2.655-3.073 2.916v1.248a.378.378 0 01-.378.378h-1.11a.378.378 0 01-.378-.378v-1.279c-1.077-.132-2.068-.54-2.792-1.11a.488.488 0 01-.064-.718l.701-.756a.488.488 0 01.65-.078 3.899 3.899 0 002.145.659c1.088 0 1.77-.407 1.77-.998 0-.565-.537-.793-1.612-.998-1.86-.354-3.218-.998-3.218-2.773 0-1.477 1.12-2.549 2.899-2.821V4.956c0-.209.169-.378.378-.378h1.11c.209 0 .378.169.378.378v1.2c.903.116 1.714.418 2.377.852a.488.488 0 01.1.716z"/>
      </svg>`,
      crypto: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 0v3.75m-16.5-3.75v3.75m16.5 0v3.75C20.25 16.153 16.556 18 12 18s-8.25-1.847-8.25-4.125v-3.75m16.5 0c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125"/>
      </svg>`,
      other: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
      </svg>`
    }
    return icons[type] || icons.other
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
    const icon = this.getTypeIcon(method.type)
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
                  class="p-1.5 text-white/40 hover:text-red-400 transition-colors">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
            </svg>
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
