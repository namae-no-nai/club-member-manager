class MembersController < ApplicationController
  def index
    @text = "ainda sei programar"
  end

  def new
    @event = Event.new
    @partners = Partner.all
    @weapons = Weapon.all
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to @event, notice: 'Registro criado com sucesso.'
    else
      @partners = Partner.all
      @weapons = Weapon.all
      render :new
    end
  end

  private

  def event_params
    params.require(:event).permit(:partner_id, :weapon_id, :activity, :date, :ammo_amount, :sheet)
  end
end
