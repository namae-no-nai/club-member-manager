class EventsController < ApplicationController
  before_action :find_partners, only: [ :new ]
  before_action :set_disable_fingerprint_verification, only: [ :new, :create ]

  def index;end

  def filter;end

  def generate_pdf
    # Validate that at least one search field is provided
    if params[:registry_certificate].blank? && params[:filiation_number].blank?
      redirect_to(filter_events_path, alert: "Por favor, preencha o Certificado de Registro ou o Número de Filiação")
      return
    end

    # Search by registry_certificate or filiation_number
    @partner = if params[:registry_certificate].present?
      Partner.find_by(registry_certificate: params[:registry_certificate])
    else
      Partner.find_by(filiation_number: params[:filiation_number])
    end

    if @partner.blank?
      redirect_to(filter_events_path, alert: "Praticante não encontrado")
      return
    end
    start_date = Date.new(
      params["[start_date(1i)]"].to_i,
      params["[start_date(2i)]"].to_i,
      params["[start_date(3i)]"].to_i
    )

    end_date = Date.new(
      params["[end_date(1i)]"].to_i,
      params["[end_date(2i)]"].to_i,
      params["[end_date(3i)]"].to_i
    )

    @events = Event.find_by_sql([
      "SELECT * FROM (
        SELECT RANK() OVER(PARTITION BY weapon_id ORDER BY date ASC) as ranking, * FROM events
      ) ranked_events
      WHERE partner_id = ? AND date BETWEEN ? AND ?",
      @partner.id, start_date, end_date
    ]).group_by(&:weapon)
  end

  def new
    @weapons = (@partners&.first&.weapons&.active || []) + (Partner.club&.weapons&.active || [])
    @partners ||= Partner.all
    @event = Event.new
    @old_practice = params[:old_practice] == "true"
    return_to_params = { old_practice: @old_practice }
    return_to_params[:partner_id] = @partners.first.id unless @old_practice
    @return_to = new_event_path(return_to_params)
    @partners_with_fingerprint = @partners.select { |p| p.fingerprint_verification.present? }.map(&:id)
  end

  def create
    update_params
    @event = nil
    @partner = Partner.find_by(id: params[:event][:partner_id])

    ActiveRecord::Base.transaction do
      practices_params.each do |practice|
        @event = Event.new(event_params.merge(practice))
        unless @event.save
          @partners = Partner.all
          @partner = Partner.find_by(id: @event.partner_id)
          @weapons = (@partner&.weapons || []) + (Partner.club&.weapons || [])
          @old_practice = params[:old_practice] == "true"
          flash.now[:alert] = "Por favor, corrija os erros abaixo."
          render :new, status: :unprocessable_entity
          return
        end
      end
    end

    redirect_to params[:return_to].presence || root_path, notice: "Registros criados com sucesso."
  end

  def edit
    @event = Event.find params[:id]
    @partner = @event.partner
    @weapons = (@partner&.weapons || []) + (Partner.club&.weapons || [])
  end


  def update
    @event = Event.find params[:id]
    if @event.update(update_event_params)
      redirect_path = params[:partner_id].present? ? partner_path(params[:partner_id]) : events_path
      redirect_to redirect_path, notice: "Registro atualizado com sucesso."
    else
      @partner = @event.partner
      @weapons = (@partner&.weapons || []) + (Partner.club&.weapons || [])
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      redirect_path = params[:partner_id].present? ? partner_path(params[:partner_id]) : last_records_path
      format.html { redirect_to redirect_path, notice: "Evento deletado com sucesso." }
      format.json { head :no_content }
    end
  end

  private

  def find_partners
    @partners = Partner.where(id: params[:partner_id]).presence
    @new_practice = @partners.present?
  end

  def set_disable_fingerprint_verification
    @disable_fingerprint_verification = Rails.application.config.disable_fingerprint_verification.present?
  end

  def update_event_params
    params.require(:event).permit(
      :partner_id, :date, :weapon_id, :activity, :ammo_amount
    )
  end

  def practices_params
    params.permit(:authenticity_token, :commit,
      practices: [ :date, :weapon_id, :activity, :ammo_amount ]
    )[:practices]
  end

  def update_params
    params[:practices].each do |practice|
      if practice[:activity] == "Outros"
        practice[:activity] = practice[:custom_activity]
      end
    end
  end

  def event_params
    params.require(:event).permit(:partner_id, :start_date, :end_date)
  end
end
