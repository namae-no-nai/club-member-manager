# frozen_string_literal: true

class PocController < ApplicationController
  def new
    @partner = Partner.new
  end

  def create
    s3_object = BucketUploaderService.new(image_data: biometric_proof_params).call

    @partner = Partner.new(partner_params)
    @partner.biometric_proof = s3_object.key

    if @partner.save
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
    )
  end

  def biometric_proof_params
    params.require(:partner).require(:biometric_proof)
  end
end
