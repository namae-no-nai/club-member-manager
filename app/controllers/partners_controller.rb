class PartnersController < ApplicationController
  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(partner_params)
    if @partner.valid?
      @partner.save!
      redirect_to register_events_path(@partner.id)
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
