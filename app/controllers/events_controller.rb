class EventsController < ApplicationController
  def index;end

  def filter;end

  def generate_pdf
    @partner = Partner.find_by(registry_certificate: params[:registry_certificate])
    start_date = params[:start_date]
    end_date = params[:end_date]
    @events = Event.includes(:weapon).where(partner_id: @partner.id, date: start_date..end_date)
                    .order(date: :desc)
                    .group_by(&:weapon)
  end

  def new
    if older_practice
      @partners = Partner.all
    else
      @partners = Partner.find(params[:partner_id])
    end
    @older_practice = older_practice
    @event = Event.new
    @weapons = Weapon.all
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

  def older_practice
    params[:older_practice].present?
  end

  def practices_params
    params.permit(practices: [ :weapon_id, :activity, :ammo_amount ])[:practices]
  end

  def event_params
    params.require(:event).permit(:partner_id, :date)
  end
end
