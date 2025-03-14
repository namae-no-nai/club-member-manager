class Event < ApplicationRecord
  belongs_to :partner

  validates :partner_id, :activity, :date,
            :ammo_amount, :sheet, presence: true
  validates :ammo_amount,
             numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sheet, numericality: { only_integer: true, equal_to: 1 }

  before_validation { self.sheet ||= 1 }
end
