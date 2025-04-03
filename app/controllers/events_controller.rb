class EventsController < ApplicationController
  before_action :find_partners, only: [:new]

  def index;end

  def filter;end

  def generate_pdf
    @partner = Partner.find_by(registry_certificate: params[:registry_certificate])
    if @partner.blank?
      redirect_to(filter_events_path, alert: 'Praticante não encontrado')
      return
    end
    start_date = params[:start_date]
    end_date = params[:end_date]
    @events = Event.includes(:weapon).where(partner_id: @partner.id, date: start_date..end_date)
                    .order(date: :desc)
                    .group_by(&:weapon)
  end

  def new
    @partners ||= Partner.all
    @event = Event.new
    @weapons = @weapons = (@partner&.weapons || []) + (Partner.club.weapons || [])
    @old_practice = params[:old_practice] == "true"
  end

  def create
    ActiveRecord::Base.transaction do
      practices_params.each do |practice|
        event = Event.new(
          event_params.merge(practice)
        )

        event.save!
      end
    end
    flash[:notice] = "Registros criados com sucesso."
    redirect_to root_path
  end

  private

  def find_partners
    @partners = Partner.where(id: params[:partner_id]).presence
    @new_practice = @partners.present?
  end

  def practices_params
    params.permit(practices: [ :weapon_id, :activity, :ammo_amount ])[:practices]
  end

  def event_params
    params.require(:event).permit(:partner_id, :date)
  end
end
