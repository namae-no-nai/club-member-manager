class CreatePartners < ActiveRecord::Migration[8.0]
  def change
    create_table :partners do |t|
      t.string :full_name
      t.string :cpf
      t.string :registry_certificate
      t.date :registry_certificate_expiration_date
      t.text :address
      t.string :afiliation_number
      t.date :first_afiliation_date

      t.timestamps
    end
  end
end
