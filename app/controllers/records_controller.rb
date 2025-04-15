class RecordsController < ApplicationController
  def last_records;end

  def last_events_records; end
  def last_partner_records
    @partners = Partner.order(created_at: :desc).page(params[:page]).per(10)
    render layout: false 
  end
end
