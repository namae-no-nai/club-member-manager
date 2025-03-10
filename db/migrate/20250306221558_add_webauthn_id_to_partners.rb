class AddWebauthnIdToPartners < ActiveRecord::Migration[8.0]
  def change
    add_column :partners, :webauthn_id, :integer
  end
end
