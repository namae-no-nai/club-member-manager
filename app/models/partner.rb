class Partner < ApplicationRecord
  validates :full_name, :cpf, :registry_certificate,
            :registry_certificate_expiration_date,
            :filiation_number, :first_filiation_date,
            presence: true
  validates :cpf, uniqueness: true

  has_many :events
  has_many :finger_prints
end
