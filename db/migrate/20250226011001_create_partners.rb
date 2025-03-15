class CreatePartners < ActiveRecord::Migration[8.0]
  def change
    create_table :partners do |t|
      t.string :full_name
      t.string :cpf
      t.string :registry_certificate
      t.date :registry_certificate_expiration_date
      t.text :address
      t.string :filiation_number
      t.date :first_filiation_date

      t.timestamps
    end
  end
end
