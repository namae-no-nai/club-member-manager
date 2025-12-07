# frozen_string_literal: true

module Fingerprint
  class CompareMultiple
    def initialize(partner:)
      @partner = partner
    end

    def call
      @matched_partners = []
      @current_template = nil

      Partner.where.not(fingerprint_verification_ciphertext: nil).find_in_batches(batch_size: 500) do |batch|
        fingerprints = batch.map(&:fingerprint_verification)
        response = send_compare_request(fingerprints)

        raise "Failed to match fingerprint against collection" unless response && response["success"]

        @current_template ||= response["captured_template"]

        # Extract matched templates and find corresponding partners
        if response["matched_templates"].present?
          response["matched_templates"].each do |match|
            template = match["template"]
            partner = Partner.find_by(fingerprint_verification: template)

            if partner
              @matched_partners << {
                partner: partner,
                score: match["score"]
              }
            end
          end
        end
      end

      @matched_partners
    rescue StandardError => e
      Rails.logger.error("Fingerprint::CompareMultiple failed: #{e.message}")
      nil
    end

    private

    def send_compare_request(fingerprints)
      base_url = Rails.application.config.fingerprint_verification_url
      endpoint = "#{base_url}/match-collection"
      uri = URI(endpoint)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"

      payload = {
        templates: fingerprints,
        captured_template: @current_template
      }.compact

      request.body = payload.to_json

      response = http.request(request)

      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
