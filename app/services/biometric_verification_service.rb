# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class BiometricVerificationService
  def api_base_url = Rails.application.config.face_comparison_url

  def initialize(current_image_data:, stored_image_key:, active_storage_image:)
    @current_image_data = current_image_data # base64 string
    @stored_image_key = stored_image_key # S3 key
    @active_storage_image = active_storage_image # ActiveStorage::Attached::One
  end

  def call
    # Extract base64 from current image (remove data URI prefix if present)
    current_image_base64 = extract_base64_string(@current_image_data)

    # Download stored image from S3 and convert to base64
    stored_image_base64 = download_stored_image_as_base64

    # Compare images using microservice API
    compare_faces(current_image_base64, stored_image_base64)
  rescue => e
    Rails.logger.error("Biometric verification error: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
    { verified: false, error: e.message }
  end

  private

  def extract_base64_string(base64_data)
    # Extract base64 data (remove data:image/png;base64, prefix if present)
    base64_data.include?(",") ? base64_data.split(",")[1] : base64_data
  end

  def download_stored_image_as_base64
    if @active_storage_image&.attached?
      return Base64.encode64(@active_storage_image.download).strip
    end

    image_content = BucketClientService.new.read_file_content(file_name: @stored_image_key)
    Base64.encode64(image_content).strip
  end

  def compare_faces(image1_base64, image2_base64)
    uri = URI("#{api_base_url}/compare-faces")

    # Decode base64 to binary data
    image1_data = Base64.decode64(image1_base64)
    image2_data = Base64.decode64(image2_base64)

    # Option 1: Create temporary files for upload (ACTIVE)
    # Net::HTTP's set_form works reliably with File objects
    image1_file = nil
    image2_file = nil

    begin
      image1_file = Tempfile.new([ "image1", ".png" ])
      image1_file.binmode
      image1_file.write(image1_data)
      image1_file.rewind

      image2_file = Tempfile.new([ "image2", ".png" ])
      image2_file.binmode
      image2_file.write(image2_data)
      image2_file.rewind

      request = Net::HTTP::Post.new(uri)
      form_data = [
        [ "image1", image1_file, { filename: "image1.png", content_type: "image/png" } ],
        [ "image2", image2_file, { filename: "image2.png", content_type: "image/png" } ]
      ]
      request.set_form(form_data, "multipart/form-data")

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 30 # 30 seconds timeout

      response = http.request(request)

      if response.code.to_i == 200
        result = JSON.parse(response.body)
        { verified: result.dig("result", "verified") || false }
      else
        error_message = "API returned status #{response.code}: #{response.body}"
        Rails.logger.error("Biometric verification API error: #{error_message}")
        { verified: false, error: error_message }
      end
    rescue JSON::ParserError => e
      error_message = "Failed to parse API response: #{e.message}"
      Rails.logger.error("Biometric verification parse error: #{error_message}")
      { verified: false, error: error_message }
    rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, SocketError => e
      error_message = "Failed to connect to biometric service: #{e.message}"
      Rails.logger.error("Biometric verification connection error: #{error_message}")
      { verified: false, error: error_message }
    rescue => e
      error_message = "Unexpected error during biometric verification: #{e.message}"
      Rails.logger.error("Biometric verification unexpected error: #{error_message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      { verified: false, error: error_message }
    ensure
      # Clean up temporary files
      if image1_file
        image1_file.close
        image1_file.unlink
      end
      if image2_file
        image2_file.close
        image2_file.unlink
      end
    end
  end
end
