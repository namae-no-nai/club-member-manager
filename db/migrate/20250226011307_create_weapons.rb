class CreateWeapons < ActiveRecord::Migration[8.0]
  def change
    create_table :weapons do |t|
      t.string :sigma
      t.string :serial_number      
      t.string :weapon_type
      t.string :brand
      t.string :caliber
      t.string :model
      t.string :action
      t.string :bore_type
      t.string :authorized_use 
      t.references :partner, foreign_key: true, null: false

      t.timestamps
    end
  end
end
