import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay", "iframe", "styleBtn"]
  static values = {
    previewUrl: String,
    downloadUrl: String,
    style: { type: String, default: "modern" }
  }

  connect() {
    this.handleEscape = this.handleEscape.bind(this)
  }

  open() {
    this.styleValue = "modern"
    this.updateActiveTab()
    this.loadPreview()

    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    this.panelTarget.classList.remove("translate-x-full")

    document.addEventListener("keydown", this.handleEscape)
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.add("opacity-0", "pointer-events-none")
    this.panelTarget.classList.add("translate-x-full")

    document.removeEventListener("keydown", this.handleEscape)
    document.body.style.overflow = ""
  }

  switchStyle(event) {
    const style = event.currentTarget.dataset.style
    if (style === this.styleValue) return

    this.styleValue = style
    this.updateActiveTab()
    this.loadPreview()
  }

  download() {
    const url = `${this.downloadUrlValue}?style=${this.styleValue}`
    window.location.href = url
  }

  handleEscape(event) {
    if (event.key === "Escape") this.close()
  }

  updateActiveTab() {
    this.styleBtnTargets.forEach((btn) => {
      const isActive = btn.dataset.style === this.styleValue
      btn.classList.toggle("bg-[#94F7AD]", isActive)
      btn.classList.toggle("text-black", isActive)
      btn.classList.toggle("font-semibold", isActive)
      btn.classList.toggle("bg-white/10", !isActive)
      btn.classList.toggle("text-white/70", !isActive)
    })
  }

  loadPreview() {
    const url = `${this.previewUrlValue}?style=${this.styleValue}`
    this.iframeTarget.src = url
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
    document.body.style.overflow = ""
  }
}
