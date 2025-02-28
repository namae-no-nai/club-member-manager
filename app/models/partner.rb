class Partner < ApplicationRecord
  validates :full_name, presence: true
  validates :cpf, presence: true, uniqueness: true
  validates :registry_certificate, presence: true
  validates :registry_certificate_expiration_date, presence: true
  validates :afiliation_number, presence: true
  validates :first_afiliation_date, presence: true

  has_many :events
  has_many :finger_prints
end
