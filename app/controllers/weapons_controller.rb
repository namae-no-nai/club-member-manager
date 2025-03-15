class WeaponsController < ApplicationController

  def index
    @partner = Partner.find_by(id: params[:partner_id])
    @weapons = Weapon.available(@partner)
    respond_to do |format|
      format.json {render json: @weapons.map(&:to_h)}
    end
  end

  def new
    @weapon = Weapon.new
    @partners = Partner.all
  end

  def create
    @weapon = Weapon.new(weapon_params)
    if @weapon.save!
      flash[:notice] = "Registros criados com sucesso."
      redirect_to root_path
    else
      render :new
    end
  end

  private

  def weapon_params
    params.require(:weapon).permit(:caliber, :sigma, :category, :partner_id)
  end
end
