WebAuthn.configure do |config|
  config.origin = ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")
  config.allowed_origins = [ Rails.configuration.webauthn_origin ]

  config.rp_name = "Clube de tiro Interarmas"
end
