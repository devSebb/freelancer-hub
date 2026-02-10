# frozen_string_literal: true

module IconHelper
  ICON_MAP = {
    # Navigation
    clients: "users",
    proposals: "file-text",
    invoices: "money",
    settings: "gear",
    sign_out: "sign-out",

    # Actions
    new: "plus",
    edit: "pencil-simple",
    delete: "trash",
    send: "paper-plane-tilt",
    export_pdf: "download-simple",
    external_link: "arrow-square-out",
    back: "arrow-left",
    close: "x",
    use_template: "plus",

    # Navigation arrows
    chevron_right: "caret-right",
    chevron_down: "caret-down",
    arrow_right: "arrow-right",
    pagination_prev: "caret-left",
    pagination_next: "caret-right",

    # Status
    check_circle: "check-circle",
    circle_outline: "circle",
    error: "x-circle",
    expired: "clock",
    paid: "check-circle",

    # Dashboard
    trending: "trend-up",
    revenue: "chart-line-up",
    pending: "file-text",
    outstanding: "money",

    # Templates
    template: "copy",
    template_empty: "file-dashed",

    # Payment methods (non-brand)
    bank_transfer: "bank",
    credit_card: "credit-card",
    crypto: "coins",
    zelle: "money",
    payment_other: "currency-circle-dollar",

    # Settings / upload
    upload: "upload-simple",

    # Home / landing page
    link: "link",
    designers: "paint-brush",
    developers: "code",
    writers: "pencil-simple",
    photo: "camera",
    marketers: "chat-circle",
    consultants: "graduation-cap",
    cta_arrow: "arrow-right",

    # Empty states (use duotone at larger size)
    clients_empty: "users",
    proposals_empty: "file-text",
    invoices_empty: "money"
  }.freeze

  # Brand icons — these are NOT Phosphor. Keep official SVGs.
  BRAND_ICONS = %i[paypal venmo cashapp].freeze

  # Usage:
  #   icon(:clients)                          → regular weight, default size
  #   icon(:clients, variant: :duotone)       → duotone weight
  #   icon(:clients, size: :lg)               → 24px
  #   icon(:clients, size: :xl, variant: :duotone)  → 48px duotone (empty states)
  #   icon(:clients, class: "text-green-400")  → custom class (use css_class:)
  #
  def icon(name, variant: :regular, size: :md, css_class: "")
    return brand_icon(name, size:, css_class:) if BRAND_ICONS.include?(name)

    phosphor_name = ICON_MAP[name]
    raise ArgumentError, "Unknown icon: #{name}. Add it to ICON_MAP." unless phosphor_name

    size_class = case size
                 when :sm then "w-4 h-4"
                 when :md then "w-5 h-5"
                 when :lg then "w-6 h-6"
                 when :xl then "w-12 h-12"
                 else "w-5 h-5"
                 end

    filename = variant == :duotone ? "#{phosphor_name}-duotone.svg" : "#{phosphor_name}.svg"
    file_path = Rails.root.join("app", "assets", "images", "icons", variant.to_s, filename)
    unless File.readable?(file_path)
      msg = "[IconHelper] Icon file not found or not readable: #{file_path}"
      Rails.logger.warn msg
      raise Errno::ENOENT, msg if Rails.env.development? || Rails.env.test?
      return "".html_safe
    end
    raw_svg = File.read(file_path)

    # Inject classes and aria-hidden into the SVG root element
    raw_svg.sub(/<svg([^>]*)>/, "<svg class=\"#{size_class} #{css_class}\" aria-hidden=\"true\"\\1>").html_safe
  end

  private

  def brand_icon(name, size:, css_class:)
    file_path = Rails.root.join("app", "assets", "images", "icons", "brand", "#{name}.svg")
    unless File.readable?(file_path)
      msg = "[IconHelper] Brand icon not found: #{file_path}"
      Rails.logger.warn msg
      raise Errno::ENOENT, msg if Rails.env.development? || Rails.env.test?
      return "".html_safe
    end
    raw_svg = File.read(file_path)
    size_class = case size
                 when :sm then "w-4 h-4"
                 when :md then "w-5 h-5"
                 when :lg then "w-6 h-6"
                 when :xl then "w-12 h-12"
                 else "w-5 h-5"
                 end
    raw_svg.sub(/<svg([^>]*)>/, "<svg class=\"#{size_class} #{css_class}\" aria-hidden=\"true\"\\1>").html_safe
  end
end
