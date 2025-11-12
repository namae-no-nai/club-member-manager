class ActiveStorageUploaderService
  def initialize(partner:, image_data:)
    @partner = partner
    @image_data = image_data
  end

  def call
    return if biometric_proof_params.blank?

    base64_data = @image_data
    base64_content = base64_data.split(",")[1]  # Remove "data:image/png;base64," prefix
    decoded_data = Base64.decode64(base64_content)

    @partner.biometric_proof_image.attach(
      io: StringIO.new(decoded_data),
      filename: "#{Time.zone.now.strftime("%d-%m-%Y_%H-%M-%S")}_#{@partner.id}.png",
      content_type: "image/png"
    )
  end
end
