# frozen_string_literal: true

class PocController < ApplicationController
  def index
  end

  def new
    @partner = Partner.new
  end

  def create
    # Handle form from index (with partner_id dropdown)
    if params[:partner_id].present?
      session[:biometric_proof] = params[:biometric_proof] if params[:biometric_proof].present?
      redirect_to poc_path(params[:partner_id])
      return
    end

    # Handle form from new (creating new partner)
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

  def show
    @partner = Partner.find(params[:id])
    @biometric_proof = session[:biometric_proof]
    # Clear the session after using it
    session.delete(:biometric_proof) if @biometric_proof.present?
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
