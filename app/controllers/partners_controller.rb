class PartnersController < ApplicationController
  def new
    @partner = Partner.new
  end

  def register
    debugger
  end

  def create
    @partner = Partner.new(partner_params)
    if @partner.valid?
      create_options = WebAuthn::Credential.options_for_create(
        user: { id: @partner.webauthn_id, name: @partner.full_name },
        exclude: @partner.credentials.map { |c| c.webauthn_id }
      )
      session[:current_registration] = { 
                                         challenge: create_options.challenge,
                                         attributes: partner_params
                                        }
      render json: create_options
    else
      render :new
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
