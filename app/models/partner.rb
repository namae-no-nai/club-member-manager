class Partner < ApplicationRecord
  validates :full_name, :cpf, :registry_certificate,
            :registry_certificate_expiration_date,
            :filiation_number, :first_filiation_date,
            presence: true
  validates :cpf, uniqueness: true
  validate :cpf_must_be_valid
  has_many :events
  has_many :credentials

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def friendly_name
    "#{registry_certificate} - #{full_name}"
  end

  private

  def cpf_must_be_valid
    errors.add(:cpf, "is invalid") unless CPF.valid?(cpf)
  end
end
