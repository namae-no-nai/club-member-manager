class CreateCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :credentials do |t|
      t.string :webauthn_id
      t.string :public_key
      t.string :nickname
      t.integer :sign_count

      t.timestamps
    end
  end
end
