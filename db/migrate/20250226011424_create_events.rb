class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.integer :partner_id
      t.integer :weapon_id
      t.string :activity
      t.date :date
      t.integer :ammo_amount
      t.integer :sheet

      t.timestamps
    end
  end
end
