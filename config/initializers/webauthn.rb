WebAuthn.configure do |config|
  config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000") ]

  config.rp_name = "Clube de tiro Interarmas"
end
