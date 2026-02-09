module PdfHelper
  def pdf_image_tag(attachment, **options)
    return nil unless attachment.attached?

    # Embed as base64 for Chrome rendering
    data = Base64.strict_encode64(attachment.download)
    src = "data:#{attachment.content_type};base64,#{data}"

    image_tag(src, **options)
  end
end
