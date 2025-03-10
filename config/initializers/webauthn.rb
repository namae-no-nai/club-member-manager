WebAuthn.configure do |config|

	config.allowed_origins = [Rails.configuration.webauthn_origin]

  config.rp_name = "Clube de tiro Interarmas"

end