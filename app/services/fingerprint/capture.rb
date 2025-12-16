# frozen_string_literal: true

module Fingerprint
  class Capture
    def initialize(partner:)
      @partner = partner
    end

    def call
      return nil if @partner.fingerprint_verification.present?

      binary_data = fetch_fingerprint_data
      return nil unless binary_data

      @partner.update(fingerprint_verification: binary_data)
      binary_data
    rescue StandardError => e
      Rails.logger.error("Fingerprint::Read failed: #{e.message}")
      nil
    end

    private

    def fetch_fingerprint_data
      base_url = Rails.application.config.fingerprint_verification_url
      endpoint = "#{base_url}#{Rails.application.config.fingerprint_read_url}"
      uri = URI(endpoint)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"

      response = http.request(request)
      response_body = JSON.parse(response&.body || "{}")

      raise "Failed to fetch fingerprint data" if !response.is_a?(Net::HTTPSuccess) || response_body["error"].present?

      Rails.logger.info("Fingerprint data: #{response_body}")

      response_body["template"]
    end
  end
end
