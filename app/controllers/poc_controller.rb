# frozen_string_literal: true

class PocController < ApplicationController
  def index
  end

  def new
    @partner = Partner.new
  end

  def create
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

  def verify
    @partner = Partner.find(params[:partner_id])
    @current_biometric_proof = params[:biometric_proof]

    # Perform verification if both images are available
    if @current_biometric_proof.present? && @partner.biometric_proof.present?
      begin
        @verification_result = BiometricVerificationService.new(
          current_image_data: @current_biometric_proof,
          stored_image_key: @partner.biometric_proof
        ).call

        # Check if verification result has an error
        if @verification_result[:error].present?
          flash[:alert] = "Erro na verificação biométrica: #{@verification_result[:error]}"
        end
      rescue => e
        Rails.logger.error("PocController#show error: #{e.class}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
        flash[:alert] = "Erro ao processar verificação biométrica: #{e.message}"
        @verification_result = { verified: false, error: e.message }
      end
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
