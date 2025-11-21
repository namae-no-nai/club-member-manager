# frozen_string_literal: true

# Service for verifying if a scanned fingerprint matches a Partner's stored template
# Supports both 1:1 verification (against specific partner) and 1:N identification (search all)
class FingerprintVerificationService
  def initialize(partner: nil, security_level: FingerprintReaderService::SL_NORMAL, score_threshold: nil)
    @partner = partner
    @security_level = security_level
    @score_threshold = score_threshold
    @sdk = nil
  end

  # Main entry point
  def call
    # Step 1-2: Initialize SDK and capture current fingerprint
    capture_result = capture_current_fingerprint

    unless capture_result[:success]
      return capture_result
    end

    current_template = capture_result[:template]

    # Step 3-4: Match against partner(s)
    if @partner
      # 1:1 Verification - match against specific partner
      verify_against_partner(current_template)
    else
      # 1:N Identification - search all partners
      search_all_partners(current_template)
    end
  ensure
    cleanup
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

  def capture_current_fingerprint
    unless initialize_sdk
      return { success: false, error: "Failed to initialize fingerprint reader SDK" }
    end

    # Get device information
    device_info = @sdk.get_device_info
    unless device_info
      return { success: false, error: "Failed to get device information" }
    end

    image_size = device_info[:image_width] * device_info[:image_height]

    # Capture fingerprint
    @sdk.set_led_on(on: true)
    image_data = @sdk.get_image(image_size)

    unless image_data
      return { success: false, error: "Failed to capture fingerprint image. Please ensure finger is placed on sensor." }
    end

    # Create template from captured image
    template = @sdk.create_template(
      image_data,
      image_width: device_info[:image_width],
      image_height: device_info[:image_height]
    )

    unless template
      return { success: false, error: "Failed to create fingerprint template from captured image." }
    end

    { success: true, template: template, device_info: device_info }
  end

  def verify_against_partner(current_template)
    # Load stored template
    stored_template = @partner.fingerprint_template

    unless stored_template
      return {
        verified: false,
        error: "No fingerprint template found for this partner. Please register fingerprint first."
      }
    end

    # Match templates
    match_result = @sdk.match_template(current_template, stored_template, security_level: @security_level)

    if match_result[:error]
      return {
        verified: false,
        error: match_result[:error]
      }
    end

    # Get matching score for additional info
    score_result = @sdk.get_matching_score(current_template, stored_template)
    score = score_result[:score] if score_result[:error].nil?

    {
      verified: match_result[:matched],
      partner: @partner,
      score: score,
      error: nil
    }
  end

  def search_all_partners(current_template)
    # Search through all partners with stored templates
    matched_partner = nil
    best_score = 0

    Partner.find_each do |partner|
      next unless partner.fingerprint_template

      stored_template = partner.fingerprint_template

      # Match templates
      match_result = @sdk.match_template(
        current_template,
        stored_template,
        security_level: @security_level
      )

      next if match_result[:error] || !match_result[:matched]

      # Get score for ranking
      score_result = @sdk.get_matching_score(current_template, stored_template)
      score = score_result[:score] if score_result[:error].nil?

      # Apply threshold if set
      if @score_threshold && score < @score_threshold
        next
      end

      # Track best match
      if score > best_score
        best_score = score
        matched_partner = partner
      end
    end

    if matched_partner
      {
        verified: true,
        partner: matched_partner,
        score: best_score,
        error: nil
      }
    else
      {
        verified: false,
        partner: nil,
        score: 0,
        error: "No matching fingerprint found"
      }
    end
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
