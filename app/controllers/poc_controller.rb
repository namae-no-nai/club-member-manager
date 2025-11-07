# frozen_string_literal: true

class PocController < ApplicationController
  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(partner_params)

    if @partner.valid?
      # For now, just render success - no persistence
      render json: { status: "success", message: "Form submitted successfully" }, status: :ok
    else
      render json: { status: "error", errors: @partner.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def partner_params
    params.require(:partner).permit(
      :full_name, :cpf, :registry_certificate,
      :registry_certificate_expiration_date, :address,
      :filiation_number, :first_filiation_date,
      :biometric_proof
    )
  end
end
