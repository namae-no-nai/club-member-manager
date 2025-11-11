# used on biometric_verification_service.rb
Rails.application.config.face_comparison_url = ENV.fetch("BIOMETRIC_VERIFICATION_SERVICE_URL", "http://localhost:7000")
