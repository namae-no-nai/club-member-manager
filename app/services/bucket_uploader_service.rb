class BucketUploaderService
  def initialize(partner:, image_data:)
    @partner = partner
    @image_data = image_data
    validate!
  end

  def call
    mime_type = @image_data.split(";")[0].split(":")[1]
    base64_data = @image_data.split(",")[1]
    image_data = Base64.decode64(base64_data)

    extension = mime_type.split("/")[1]

    # TODO: pick a better naming convention
    file_name = "biometric_proofs/#{SecureRandom.uuid}.#{extension}"

    s3_object = BucketClientService.new.upload_file(
      file_name: file_name,
      file_content: image_data
    )

    @partner.biometric_proof = s3_object.key
  end

  def validate!
    raise "Image data is required" if @image_data.blank?
    raise "Image must be on the format data:image/png;base64,iVBORw0KGgo..." unless @image_data.start_with?("data:")
  end
end
