# frozen_string_literal: true

class BiometricProofImagesController < ApplicationController
  def show
    @partner = Partner.find(params[:id])

    if @partner.biometric_proof_image.attached?
      send_data @partner.biometric_proof_image.download,
                type: @partner.biometric_proof_image.content_type,
                filename: @partner.biometric_proof_image.filename.to_s,
                disposition: params[:disposition] || "inline"
    else
      head :not_found
    end
  end

  def create
    @partner = Partner.find(params[:id])

    if @partner.biometric_proof_image.attached?
      flash[:alert] = "Já existe uma foto biométrica cadastrada. Remova a foto atual antes de adicionar uma nova."
      redirect_to edit_partner_path(@partner)
      return
    end

    if biometric_proof_params.blank?
      flash[:alert] = "Envie uma foto biométrica."
      redirect_to edit_partner_path(@partner)
      return
    end

    begin
      ActiveStorageUploaderService.new(partner: @partner, image_data: biometric_proof_params).call
      flash[:notice] = "Foto biométrica adicionada com sucesso."
    rescue => e
      Rails.logger.error("BiometricProofImagesController#create error: #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      flash[:alert] = "Erro ao adicionar foto biométrica: #{e.message}"
    end

    redirect_to edit_partner_path(@partner)
  end

  def destroy
    @partner = Partner.find(params[:id])

    if @partner.biometric_proof_image.attached?
      @partner.biometric_proof_image.purge
      flash[:notice] = "Foto biométrica removida com sucesso."
    else
      flash[:alert] = "Nenhuma foto biométrica encontrada para remover."
    end

    redirect_to edit_partner_path(@partner)
  end

  private

  def biometric_proof_params
    params.require(:biometric_proof)
  rescue ActionController::ParameterMissing
    nil
  end
end
