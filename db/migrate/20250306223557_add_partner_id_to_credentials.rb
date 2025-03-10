class AddPartnerIdToCredentials < ActiveRecord::Migration[8.0]
  def change
    add_reference :credentials, :partner, null: false, foreign_key: true
  end
end
