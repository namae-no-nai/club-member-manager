# used on biometric_verification_service.rb
Rails.application.config.fingerprint_verification_url = ENV.fetch("FINGERPRINT_VERIFICATION_SERVICE_URL", "http://localhost:8000")

# Fingerprint API endpoints
Rails.application.config.fingerprint_read_url = ENV.fetch("FINGERPRINT_READ_ENDPOINT", "/capture")
Rails.application.config.fingerprint_match_url = ENV.fetch("FINGERPRINT_MATCH_ENDPOINT", "/compare")

Rails.application.config.disable_fingerprint_verification = ENV.fetch("FINGERPRINT_DISABLE", false)
