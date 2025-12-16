class PartnersController < ApplicationController
  def bulk_partner
  end

  def csv_create
    if params[:file].present?
      partners = CsvToPartnerService.new(params[:file]).process
      valid_partners = partners.select(&:valid?)

      if valid_partners.any?
        valid_partners.each(&:save)
        redirect_to root_path,
          notice: "#{valid_partners.count} sócios criados com sucesso."
      else
        flash.now[:alert] = "Nenhum parceiro válido encontrado no CSV."
        render :bulk
      end
    else
      flash.now[:alert] = "Envie um arquivo CSV."
      render :bulk
    end
  end

  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(partner_params)
    if @partner.save
      redirect_to params[:return_to] if params[:return_to].present?

      render partner_path(@partner)
    else
      render :new
    end
  end

  def show
    @partner = Partner.find params[:id]
  end

  def edit
    @partner = Partner.find params[:id]
  end

  def update
    @partner = Partner.find(params[:id])
    if @partner.update(partner_params)
      redirect_to last_records_path, notice: "Sócio atualizado com sucesso."
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
