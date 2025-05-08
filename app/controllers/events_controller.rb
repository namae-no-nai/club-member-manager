class EventsController < ApplicationController
  before_action :find_partners, only: [ :new ]

  def index;end

  def filter;end

  def generate_pdf
    @partner = Partner.find_by(
        registry_certificate: params[:registry_certificate]
      )
    if @partner.blank?
      redirect_to(filter_events_path, alert: "Praticante não encontrado")
      return
    end
    start_date = params[:start_date]
    end_date = params[:end_date]
    @events = Event.includes(:weapon)
                    .where(partner_id: @partner.id, date: start_date..end_date)
                    .order(date: :desc)
                    .group_by(&:weapon)
  end

  def new
    @partners ||= Partner.all
    @event = Event.new
    @weapons = (@partner&.weapons || []) + (Partner.club&.weapons || [])
    @old_practice = params[:old_practice] == "true"
    return_to_params = { old_practice: @old_practice }
    return_to_params[:partner_id] = @partners.first.id unless @old_practice
    @return_to = new_event_path(return_to_params)
  end

  def create
    update_params
    @event = nil
  
    ActiveRecord::Base.transaction do
      practices_params.each do |practice|
        @event = Event.new(event_params.merge(practice))
        unless @event.save
          debugger
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

    redirect_to root_path, notice: "Registros criados com sucesso."
  end

  def edit
    @event = Event.find params[:id]
    @partner = @event.partner
    @weapons = (@partner&.weapons || []) + (Partner.club&.weapons || [])
  end


  def update
    @event = Event.find params[:id]
    if @event.update(update_event_params)
      redirect_to events_path, notice: "Registro atualizado com sucesso."
    else
      @partner = @event.partner
      @weapons = (@partner&.weapons || []) + (Partner.club&.weapons || [])
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_partners
    @partners = Partner.where(id: params[:partner_id]).presence
    @new_practice = @partners.present?
  end

  def update_event_params
    params.require(:event).permit(
      :partner_id, :date, :weapon_id, :activity, :ammo_amount
    )
  end

  def practices_params
    params.permit(
      practices: [ :weapon_id, :activity, :ammo_amount ]
    )[:practices]
  end

  def update_params
    params[:practices].each do |practice|
      if practice[:activity] == 'Outros'
        practice[:activity] = practice[:custom_activity]
      end
    end
  end

  def event_params
    params.require(:event).permit(:partner_id, :date)
  end
end
