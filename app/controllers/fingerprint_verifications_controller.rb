class FingerprintVerificationsController < ApplicationController
  def index
    # Render the fingerprint verification page with loader
  end

  def search
    matched_partners = Fingerprint::CompareMultiple.new.call

    if matched_partners.nil?
      render json: { success: false, error: "Erro ao comparar biometria" }, status: :unprocessable_entity
    elsif matched_partners.empty?
      render json: { success: true, partners: [], message: "Nenhum sócio encontrado" }
    else
      partners_data = matched_partners.map do |match|
        {
          id: match[:partner].id,
          name: match[:partner].full_name,
          cpf: match[:partner].cpf,
          registry_certificate: match[:partner].registry_certificate,
          filiation_number: match[:partner].filiation_number,
          score: match[:score],
          friendly_name: match[:partner].friendly_name
        }
      end

      render json: { success: true, partners: partners_data }
    end
  end

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
