class ChangeWebauthnIdToBinaryInCredentials < ActiveRecord::Migration[8.0]
  def change
    change_column :credentials, :webauthn_id, :binary
  end
end
