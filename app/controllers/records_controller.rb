class RecordsController < ApplicationController
  def last_records;end

  def last_events_records
    @events = Event.order(created_at: :desc).page(params[:page]).per(1)
    render layout: false
  end
  def last_partner_records
    @partners = Partner.order(created_at: :desc).page(params[:page]).per(1)
    render layout: false
  end
end
