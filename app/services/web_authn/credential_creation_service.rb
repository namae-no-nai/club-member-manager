module WebAuthn
  class CredentialCreationService
    def initialize(partner:, request:)
      @partner = partner
      @request = request
    end

    def call
      WebAuthn::Credential.options_for_create(
        user: {
          id: @partner.webauthn_id,         # valor binário (ex: 16 bytes random)
          name: @partner.cpf,               # ex: "usuario@localhost"
          display_name: @partner.cpf        # ex: "Usuário Local"
        },
        rp: {
          name: @request.host,
          id: @request.host
        },
        pub_key_cred_params: [
          { type: "public-key", alg: -7 },     # ES256
          { type: "public-key", alg: -257 }    # RS256
        ],
        exclude: @partner.credentials.pluck(:webauthn_id),
        authenticator_selection: {
          authenticator_attachment: "cross-platform",
          user_verification: "preferred",
          resident_key: "preferred"
        },
        timeout: 60_000,
        attestation: "none"
      )
    end
  end
end
