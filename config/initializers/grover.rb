Grover.configure do |config|
  config.options = {
    format: "A4",
    # Required for CSS backgrounds and /assets/ font URLs when HTML is inlined
    display_url: ENV.fetch("GROVER_DISPLAY_URL", "http://localhost:3000"),
    # Page margins are controlled by CSS @page in each theme so all pages get equal padding
    margin: { top: "0", bottom: "0", left: "0", right: "0" },
    print_background: true,
    prefer_css_page_size: true,
    emulate_media: "print",
    display_header_footer: true,
    header_template: '<span></span>',
    footer_template: '<div style="width: 100%; font-size: 8px; color: #999; text-align: right; padding-right: 1cm;"><span class="pageNumber"></span></div>'
  }
end
