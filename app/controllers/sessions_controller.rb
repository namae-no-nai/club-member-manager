# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    @partners = Partner.all
  end

  def create
    partner = Partner.find(params[:partner_id])
    
    allow_credentials = partner.credentials.map do |cred|
     {
      id: Base64.urlsafe_encode64(cred.webauthn_id, padding: false),
      type: 'public-key',
      transports: ['usb']
    }
    end

    get_options = WebAuthn::Credential.options_for_get(
      allow_credentials:,
      user_verification: "preferred",
      timeout: 60_000
    )

    session[:current_authentication] = {
      challenge: get_options.challenge,
      partner_id: partner.id
    }

    respond_to do |format|
      format.json { render json: { publicKey: get_options } } 
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_get(params[:credential])

    partner = Partner.find(session[:current_authentication]["partner_id"])

    credential = partner.credentials.find_by(
      webauthn_id: Base64.urlsafe_decode64(webauthn_credential.id)
    )

    begin
      webauthn_credential.verify(
        session[:current_authentication]["challenge"],
        public_key: credential.public_key,
        sign_count: credential.sign_count,
        user_verification: false
      )

      credential.update!(sign_count: webauthn_credential.sign_count)

      sign_in(partner)

      render json: {
        redirect_to: new_event_path(partner_id: partner.id)
      }, status: :ok
    rescue WebAuthn::Error => e
      render json: { error: "Verification failed: #{e.message}" },
             status: :unprocessable_entity
    ensure
      session.delete(:current_authentication)
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end
end
