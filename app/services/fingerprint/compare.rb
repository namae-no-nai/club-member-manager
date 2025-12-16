# frozen_string_literal: true

module Fingerprint
  class Compare
    def initialize(partner:)
      @partner = partner
    end

    def call
      raise "Fingerprint verification is not present" unless @partner.fingerprint_verification.present?

      match_result = send_compare_request
      raise "Failed to match fingerprint" unless match_result

      match_result["match"] == true
    rescue StandardError => e
      Rails.logger.error("Fingerprint::Match failed: #{e.message}")
      nil
    end

    private

    def send_compare_request
      base_url = Rails.application.config.fingerprint_verification_url
      endpoint = "#{base_url}#{Rails.application.config.fingerprint_match_url}"
      uri = URI(endpoint)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"

      payload = {
        template: @partner.fingerprint_verification,
        security_level: 5
      }
      request.body = payload.to_json

      response = http.request(request)

      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
