class CreateWeapons < ActiveRecord::Migration[8.0]
  def change
    create_table :weapons do |t|
      t.string :caliber
      t.string :category
      t.string :sigma

      t.timestamps
    end
  end
end
