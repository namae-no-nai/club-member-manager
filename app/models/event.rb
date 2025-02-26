class Event < ApplicationRecord
	belongs_to :partner
  belongs_to :weapon

  validates :partner_id, presence: true
  validates :weapon_id, presence: true
  validates :activity, presence: true,
                       inclusion: { in: ["training", "competition"],
                       message: "%{value} is not a valid activity" }
  validates :date, presence: true
  validates :ammo_amount, presence: true,
                          numericality: {
                            only_integer: true, greater_than_or_equal_to: 0
                          }
  validates :sheet, presence: true,
                    numericality: { only_integer: true, equal_to: 1 }

  before_validation :set_default_sheet

  private def set_default_sheet
    self.sheet ||= 1
  end
end