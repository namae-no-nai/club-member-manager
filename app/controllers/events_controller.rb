class EventsController < ApplicationController
  def index
    @partner = Partner.last
    start_date = 1.year.ago.to_date
    end_date = Date.today
    @events= Event.includes(:weapon).where(partner_id: @partner.id, date: start_date..end_date)
     .order(date: :desc)
     .group_by(&:weapon)
  end

  def new
    @event = Event.new
    @partners = Partner.all
    @weapons = Weapon.all
  end

  def create
    @events = []

    event_params[:practices].each do |practice|
      event = Event.new(
        partner_id: event_params[:partner_id],
        date: event_params[:date],
        sheet: event_params[:sheet],
        weapon_id: practice[:weapon_id],
        activity: practice[:activity],
        ammo_amount: practice[:ammo_amount]
      )

      if event.save
        @events << event
      else
        @partners = Partner.all
        @weapons = Weapon.all
        return render :new
      end
    end

    flash[:notice] = "Registros criados com sucesso."
    redirect_to @events.first || events_path
  end

  private

  def event_params
    practice_params = params.require(:event).permit(:partner_id, :date, :sheet)
    practice_params[:practices] = params[:practices] if params[:practices].is_a?(Array)

    practice_params
  end
end
