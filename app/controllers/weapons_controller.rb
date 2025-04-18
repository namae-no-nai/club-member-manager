class WeaponsController < ApplicationController
  def index
    @partner = Partner.find_by(id: params[:partner_id])
    @weapons = Weapon.available(@partner)
    respond_to do |format|
      format.json { render json: @weapons.map(&:to_h) }
    end
  end

  def new
    @weapon = Weapon.new
    @partners = Partner.all
  end

  def create
    custom_action
    @weapon = Weapon.new(weapon_params)
    if @weapon.save!
      flash[:notice] = "Registros criados com sucesso."
      redirect_to root_path
    else
      render :new
    end
  end

  def edit
    @weapon = Weapon.find params[:id]
    @partners = Partner.all
  end

  def update
    custom_action
    @weapon = Weapon.find params[:id]
    if @weapon.update(weapon_params)
      flash[:notice] = "Registros criados com sucesso."
      redirect_to root_path
    else
      render :new
    end
  end

  private

  def weapon_params
    params.require(:weapon).permit(
      :partner_id, :sigma, :serial_number, :weapon_type, :brand, :caliber, :model,
      :action, :bore_type, :authorized_use
    )
  end

  def custom_action
    if params[:weapon][:action] == "outros"
      params[:weapon][:action] = params[:custom_action]
    end
  end
end
