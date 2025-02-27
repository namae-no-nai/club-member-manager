class PdfsController < ApplicationController
  def generate
    render pdf: "document", template: "pdfs/document"
  end
end
