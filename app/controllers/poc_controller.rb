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
      redirect_to edit_partner_path(@partner)
    else
      flash[:alert] = "Erro ao registrar praticante: #{@partner.errors.full_messages.join(', ')}"
      redirect_to new_poc_path
    end

  rescue => e
    Rails.logger.error("PocController#create error: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
    flash[:alert] = "Erro ao tentar registrar praticante: #{e.message}"
    redirect_to new_poc_path
  end

  def verify
    @partner = Partner.find(params[:partner_id])
    @current_biometric_proof = params[:biometric_proof]

    redirect_to index_poc_path unless @current_biometric_proof.present? && \
                                      @partner.biometric_proof.present?

    @verification_result = BiometricVerificationService.new(
      current_image_data: @current_biometric_proof,
      stored_image_key: @partner.biometric_proof
    ).call

    # Check if verification result has an error
    if @verification_result[:error].present?
      flash[:alert] = "Erro na verificação biométrica: #{@verification_result[:error]}"
      redirect_to index_poc_path
    end

    redirect_to edit_partner_path(@partner)
  rescue => e
    Rails.logger.error("PocController#show error: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
    flash[:alert] = "Erro ao processar verificação biométrica: #{e.message}"
    @verification_result = { verified: false, error: e.message }
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
