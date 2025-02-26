class CreateFingerPrints < ActiveRecord::Migration[8.0]
  def change
    create_table :finger_prints do |t|
      t.string :credentials
      t.integer :partner_id
      t.text :description

      t.timestamps
    end
  end
end
