class PartnersController < ApplicationController
  def bulk_partner
  end

  def csv_create
    if params[:file].present?
      partners = CsvToPartnerService.new(params[:file]).process

      if partners.any?
        partners.each(&:save)
        redirect_to root_path, notice: "#{partners.count} sócios criados com sucesso."
      else
        redirect_to bulk_partners_path, alert: "Nenhum parceiro válido encontrado no CSV."
      end
    else
      redirect_to bulk_partners_path, alert: "Envie um arquivo CSV."
    end
  end

  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(partner_params)
    if @partner.save
      redirect_to params[:return_to] || new_event_path(partner_id: @partner.id, old_practice: true)
    else
      render :new
    end
  end

  def edit
    @partner = Partner.find params[:id]
  end

  def update
    @partner = Partner.find(params[:id])
    if @partner.update(partner_params)
      redirect_to last_records_path, notice: 'Sócio atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def partner_params
    params.require(:partner).permit(
    :file,
    :full_name, :cpf, :registry_certificate,
    :registry_certificate_expiration_date, :address,
    :filiation_number, :first_filiation_date
    )
  end
end
