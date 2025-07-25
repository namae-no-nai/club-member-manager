# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(partner_params)
    return render :new unless @partner.valid?

    create_options = WebAuthn::CredentialCreationService.new(
      partner: @partner,
      request: request
    ).call
    
    session[:current_registration] = {
      challenge: create_options.challenge,
      partner_attributes: @partner.attributes
    }

    respond_to do |format|
      format.json { render json: create_options }
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_create(params)

    partner_attributes = session[:current_registration]["partner_attributes"]
    partner_id = partner_attributes["id"]

    partner = if partner_id.present?
                Partner.find_by(id: partner_id) || Partner.new(partner_attributes)
              else
                Partner.new(partner_attributes)
              end

    begin
      webauthn_credential.verify( session[:current_registration]["challenge"], user_verification: false )

      partner.credentials.build(
        webauthn_id: webauthn_credential.raw_id,
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
