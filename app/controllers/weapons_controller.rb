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
  
    if @weapon.save
      # Respond to Turbo or AJAX
      respond_to do |format|
        format.html do
          flash[:notice] = "Registros criados com sucesso."
          redirect_to params[:weapon][:return_to].presence || root_path, notice: 'Arma criada com sucesso.'
        end
        format.json { render json: @weapon, status: :created }
      end
    else
      @partners = Partner.all
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @weapon.errors.full_messages }, status: :unprocessable_entity }
      end
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

  def archive
    @weapon = Weapon.find params[:id]
    @weapon.update(archive_params)

    redirect_to last_weapons_records_path(partner_id: @weapon.partner.id)
  end

  private

  def archive_params
    if @weapon.archived_at?
      return {archived_at:nil,
        archived_reason: params.dig(:weapons, :archived_reason)
      }
    end

    {
      archived_at: Time.current,
      archived_reason: params.dig(:weapons, :archived_reason)
    }
  end

  def weapon_params
    params.require(:weapon).permit(
      :partner_id, :sigma, :serial_number, :weapon_type, :brand, :caliber,
      :model, :action, :bore_type, :authorized_use,
      :archived_at, :archived_reason
    )
  end

  def custom_action
    if params[:weapon][:action] == "outros"
      params[:weapon][:action] = params[:custom_action]
    end
  end
end
