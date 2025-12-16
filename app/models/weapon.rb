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
    club_id = Partner.club&.id
    partner_id = partner&.id

    where(partner_id: [ partner_id, club_id ].compact)
      .where(archived_at: nil)
      .order(Arel.sql("CASE WHEN partner_id = #{sanitize_sql(club_id)} THEN 1 ELSE 0 END, id"))
  }

  scope :active, -> { where(archived_at: nil) }

  def to_h
    { id:, friendly_name: }
  end

  def friendly_name
    prefix = partner_id == Partner.club&.id ? "🏛️ [CLUBE] " : ""
    "#{prefix}#{weapon_type.humanize} - #{caliber} - #{brand} - #{model}"
  end

  def self.suggested_actions
    SUGGESTED_ACTIONS
  end
end
