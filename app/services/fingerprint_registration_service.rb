# frozen_string_literal: true

# Service for registering (storing) a fingerprint template for a Partner
class FingerprintRegistrationService
  def initialize(partner:, quality_threshold: 50)
    @partner = partner
    @quality_threshold = quality_threshold
    @sdk = nil
  end

  def call
    # Step 1: Initialize SDK
    unless initialize_sdk
      return { success: false, error: "Failed to initialize fingerprint reader SDK" }
    end

    # Step 2: Get device information
    device_info = @sdk.get_device_info
    unless device_info
      cleanup
      return { success: false, error: "Failed to get device information" }
    end

    image_size = device_info[:image_width] * device_info[:image_height]

    # Step 3: Capture fingerprint image
    @sdk.set_led_on(on: true)
    image_data = @sdk.get_image(image_size)

    unless image_data
      cleanup
      return { success: false, error: "Failed to capture fingerprint image. Please ensure finger is placed on sensor." }
    end

    # Step 4: Check image quality
    quality = @sdk.get_image_quality(
      device_info[:image_width],
      device_info[:image_height],
      image_data
    )

    unless quality
      cleanup
      return { success: false, error: "Failed to assess image quality" }
    end

    if quality < @quality_threshold
      cleanup
      return {
        success: false,
        error: "Image quality too low (#{quality}/100). Please try again with better finger placement.",
        quality: quality
      }
    end

    # Step 5: Create template from image
    template = @sdk.create_template(
      image_data,
      image_width: device_info[:image_width],
      image_height: device_info[:image_height]
    )

    unless template
      cleanup
      return { success: false, error: "Failed to create fingerprint template. Please try again." }
    end

    # Step 6: Store template in database
    begin
    #   @partner.update!(
    #     fingerprint_template: template,
    #     fingerprint_quality: quality,
    #     fingerprint_registered_at: Time.current,
    #     fingerprint_device_info: device_info
    #   )

    #   Rails.logger.info("Fingerprint registered for partner #{@partner.id}: quality=#{quality}, template_size=#{template.bytesize}")

    #   {
    #     success: true,
    #     quality: quality,
    #     template_size: template.bytesize,
    #     device_info: device_info
    #   }
    # rescue => e
    #   Rails.logger.error("Failed to save fingerprint template: #{e.message}")
    #   Rails.logger.error(e.backtrace.join("\n"))
    #   { success: false, error: "Failed to save fingerprint: #{e.message}" }
    ensure
      cleanup
    end
    template
  end

  private

  def initialize_sdk
    @sdk = FingerprintReaderService.new

    unless @sdk.create
      Rails.logger.error("Failed to create SDK instance")
      return false
    end

    unless @sdk.init(device_name: FingerprintReaderService::DEV_AUTO)
      Rails.logger.error("Failed to initialize SDK")
      @sdk.terminate
      return false
    end

    unless @sdk.open_device(device_id: 0)
      Rails.logger.error("Failed to open device")
      @sdk.terminate
      return false
    end

    true
  end

  def cleanup
    return unless @sdk

    @sdk.set_led_on(on: false) if @sdk.initialized
    @sdk.close_device
    @sdk.terminate
    @sdk = nil
  rescue => e
    Rails.logger.error("Error during cleanup: #{e.message}")
  end
end
