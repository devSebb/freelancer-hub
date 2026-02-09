Grover.configure do |config|
  config.options = {
    format: "A4",
    margin: {
      top: "1cm",
      bottom: "1.5cm",
      left: "1cm",
      right: "1cm"
    },
    print_background: true,
    prefer_css_page_size: true,
    emulate_media: "print"
  }
end
