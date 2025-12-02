class FingerprintVerificationsController < ApplicationController
  def capture
    @partner = Partner.find params[:partner_id]
    @fingerprint_verification = Fingerprint::Capture.new(partner: @partner).call

    if @fingerprint_verification.present?
      redirect_to partner_path(@partner), notice: "Biometria capturada com sucesso."
    else
      redirect_to partner_path(@partner), alert: "Erro ao capturar biometria."
    end
  end

  def compare
    @partner = Partner.find params[:partner_id]
    @fingerprint_verification = Fingerprint::Compare.new(partner: @partner).call

    if @fingerprint_verification.present?
      redirect_to partner_path(@partner), notice: "Biometria verificada com sucesso."
    else
      redirect_to partner_path(@partner), alert: "Erro ao verificar biometria."
    end
  end
end
