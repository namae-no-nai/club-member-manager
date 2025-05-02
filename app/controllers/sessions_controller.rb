# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    @partners = Partner.all
  end

  def create
    partner = Partner.find(params[:partner_id])

    get_options = WebAuthn::Credential.options_for_get(
      allow: partner.credentials.pluck(:webauthn_id),
      user_verification: "required"
    )

    session[:current_authentication] = {
      challenge: get_options.challenge, id: partner.id
    }

    respond_to do |format|
      format.json { render json: get_options }
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_get(params)

    partner = Partner.find(session[:current_authentication]["id"])
    credential = partner.credentials.find_by(
      webauthn_id: Base64.strict_encode64(webauthn_credential.raw_id)
    )

    begin
      webauthn_credential.verify(
        session[:current_authentication]["challenge"],
        public_key: credential.public_key,
        sign_count: credential.sign_count,
        user_verification: true
      )

      credential.update!(sign_count: webauthn_credential.sign_count)
      sign_in(partner)

      render json: {
        redirect_to: new_event_path(partner_id: partner.id)
      }, status: :ok
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}",
        status: :unprocessable_entity
    ensure
      session.delete(:current_authentication)
    end
  end

  def destroy
    sign_out

    redirect_to root_path
  end

  private

  def session_params
    params.require(:session).permit(:username)
  end
end
