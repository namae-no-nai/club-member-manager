WebAuthn.configure do |config|
  config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000") ]

  config.origin = "http://localhost:3000"
  config.rp_id = "localhost"
  config.rp_name = "test"
end
