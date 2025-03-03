class PdfsController < ApplicationController
  def document
    html = render_to_string(template: "events/index", layout: false)

    debugger
    pdf = WickedPdf.new.pdf_from_string(html, {
      stylesheet: Rails.root.join("app/assets/tailwind/application.css"),
      image_path: Rails.root.join("public").to_s
    })

    send_data pdf, filename: "document.pdf", type: "application/pdf", disposition: "inline"
  end
end
