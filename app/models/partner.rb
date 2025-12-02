class Partner < ApplicationRecord
  has_encrypted :fingerprint_verification

  validates :cpf, uniqueness: true
  validate :cpf_must_be_valid
  has_many :events
  has_many :credentials
  has_many :weapons

  def self.club
    find_by(registry_certificate: 66098)
  end

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def friendly_name
    "#{filiation_number} - #{full_name}"
  end

  private

  def cpf_must_be_valid
    errors.add(:cpf, "is invalid") unless CPF.valid?(cpf)
  end
end
