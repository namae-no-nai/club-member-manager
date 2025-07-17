# frozen_string_literal: true

class CredentialsController < ApplicationController
  before_action :enforce_current_user

  def index;end

  def create
    challenge = WebAuthn.generate_challenge

    create_options = WebAuthn::Credential.options_for_create(
    user: {
      id: current_user.webauthn_id,           # valor binário (ex: 16 bytes random)
      name: current_user.email,                # ex: "usuario@localhost"
      display_name: current_user.name          # ex: "Usuário Local"
    },
    rp: {
      name: "Meu App Local",
      id: request.host                         # domínio atual (ex: localhost)
    },
    pub_key_cred_params: [
      { type: "public-key", alg: -7 },        # ES256
      { type: "public-key", alg: -257 }       # RS256
    ],
    authenticator_selection: {
      authenticator_attachment: "cross-platform",
      user_verification: "discouraged",
      resident_key: "discouraged"
    },
    timeout: 60000,
    attestation: "none",
    challenge: challenge
  )

    session[:current_registration] = { challenge: create_options.challenge }

    respond_to do |format|
      format.json { render json: create_options }
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_create(params)

    begin
      webauthn_credential.verify(session[:current_registration]["challenge"], user_verification: true)

      credential = current_user.credentials.find_or_initialize_by(
        webauthn_id: Base64.strict_encode64(webauthn_credential.raw_id)
      )

      if credential.update(
        nickname: params[:credential_nickname],
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )
        render json: { status: "ok" }, status: :ok
      else
        render json: "Couldn't add your Security Key", status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:current_registration)
    end
  end

  def destroy
    if current_user.blank?
      redirect_to new_session_path
    end

    if current_user&.can_delete_credentials?
      current_user.credentials.destroy(params[:id])
    end

    redirect_to root_path
  end

  private

  def enforce_current_user
    if current_user.blank?
      redirect_to new_session_path
    end
  end
end
