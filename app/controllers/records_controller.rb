class RecordsController < ApplicationController
  def last_records
  end

  def last_events_records
    @events = fetch_filtered_events
    @partner_id = params[:partner_id]
    render layout: false
  end

  def last_weapons_records
    @weapons = Weapon.where(partner_id: params[:partner_id])
                     .order(created_at: :desc)
                     .page(params[:page]).per(10)
    @partner_id = params[:partner_id]
    render layout: false
  end

  def last_partner_records
    @partners = fetch_filtered_partners
    render layout: false
  end

  private

  def fetch_filtered_partners
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      return Partner.where("LOWER(partners.full_name) LIKE ?", search_term)
           .order(created_at: :desc)
           .page(params[:page]).per(10)
    end
    Partner.order(created_at: :desc).page(params[:page]).per(10)
  end

  def fetch_filtered_events
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      return Event.joins(:partner)
           .where("LOWER(partners.full_name) LIKE ?", search_term)
           .order(created_at: :desc)
           .page(params[:page]).per(10)
    elsif params[:partner_id].present?
      Event.where(partner_id: params[:partner_id])
           .order(created_at: :desc)
           .page(params[:page]).per(10)
    else
      Event.order(created_at: :desc)
           .page(params[:page]).per(10)
    end
  end
end

