class Weapon < ApplicationRecord
  SUGGESTED_ACTIONS = [
    "semi-automático",
    "repetição",
    "outros"
  ].freeze

  enum :weapon_type, {
    pistola: 0,
    revolver: 1,
    carabina: 2,
    espingarda: 3
  }

  enum :bore_type, {
    raiada: 0,
    lisa: 1
  }

  enum :authorized_use, {
    permitido: 0,
    restrito: 1
  }
  
  validates :partner_id, :sigma, :serial_number, :weapon_type, :brand, :caliber,
            :model, :action, :bore_type, :authorized_use, presence: true

  has_many :events
  belongs_to :partner

  scope :available, ->(partner) {
    where(partner_id: [ partner.id, Partner.club.id ]) }

  def to_h
    { id:, friendly_name: }
  end

  def friendly_name
    "#{weapon_type.humanize} - #{caliber} - #{brand} - #{model}"
  end

  def self.suggested_actions
    SUGGESTED_ACTIONS
  end
end
