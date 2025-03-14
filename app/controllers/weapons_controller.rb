class WeaponsController < ApplicationController
  def new
    @weapon = Weapon.new
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
    params.require(:weapon).permit(:caliber, :sigma, :category)
  end
end
