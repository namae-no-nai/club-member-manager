class Event < ApplicationRecord
  SUGGESTED_ACTIVITIES = [
    'Treino',
    'Competição',
    'Outros'
  ]

  belongs_to :partner
  belongs_to :weapon

  validates :partner_id, :activity, :weapon_id, :date,
            :ammo_amount, :sheet, presence: true
  validates :ammo_amount,
             numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sheet, numericality: { only_integer: true, equal_to: 1 }

  before_validation { self.sheet ||= 1 }

  def self.suggested_activities
    SUGGESTED_ACTIVITIES
  end
end
