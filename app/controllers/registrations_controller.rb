# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(partner_params)
    return render :new unless @partner.valid?

    challenge = WebAuthn.generate_challenge

    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: @partner.webauthn_id,           # valor binário (ex: 16 bytes random)
        name: @partner.email,                # ex: "usuario@localhost"
        display_name: @partner.name          # ex: "Usuário Local"
      },
      rp: {
        name: "Meu App Local",
        id: request.host                         # domínio atual (ex: localhost)
      },
      pub_key_cred_params: [
        { type: "public-key", alg: -7 },        # ES256
        { type: "public-key", alg: -257 }       # RS256
      ],
      exclude: @partner.credentials.pluck(:webauthn_id),
      authenticator_selection: {
        authenticator_attachment: "cross-platform",
        user_verification: "discouraged",
        resident_key: "discouraged"
      },
      timeout: 60000,
      attestation: "none",
      challenge: challenge
    )

    session[:current_registration] = { challenge: create_options.challenge, partner_attributes: @partner.attributes }

    respond_to do |format|
      format.json { render json: create_options }
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_create(params)

    partner = Partner.new(session[:current_registration]["partner_attributes"])

    begin
      webauthn_credential.verify(
        session[:current_registration]["challenge"], user_verification: true
      )

      partner.credentials.build(
        webauthn_id: Base64.strict_encode64(webauthn_credential.raw_id),
        nickname: params[:credential_nickname],
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )

      if partner.save
        sign_in(partner)

        render json: {
          redirect_to: new_event_path(partner_id: partner.id)
        }, status: :ok
      else
        render json: "Couldn't register your Security Key",
          status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}",
        status: :unprocessable_entity
    ensure
      session.delete(:current_registration)
    end
  end

  private

  def partner_params
    params.require(:partner).permit(
      :full_name, :cpf, :registry_certificate,
      :registry_certificate_expiration_date, :address,
      :filiation_number, :first_filiation_date
    )
  end
end
