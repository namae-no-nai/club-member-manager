class Event < ApplicationRecord
  SUGGESTED_ACTIVITIES = %w[Treino Competição Outros].freeze

  belongs_to :partner
  belongs_to :weapon

  validates :partner_id, :activity, :weapon_id, :date,
            :ammo_amount, :sheet, presence: true
  validates :ammo_amount,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sheet,
            numericality: { only_integer: true, equal_to: 1 }

  before_validation { self.sheet ||= 1 }
  before_create :assign_register_number
  after_destroy :renumber_register_numbers

  def self.suggested_activities
    SUGGESTED_ACTIVITIES
  end

  private

  def assign_register_number
    events = Event.where(weapon_id: weapon_id).order(:date, :id)

    position = events.count { |e| e.date <= date }

    self.register_number = position + 1

    events.where("date >= ?", date).update_all("register_number = register_number + 1")
  end

  def renumber_register_numbers
    events = Event.where(weapon_id: weapon_id).order(:date, :id)

    events.each_with_index do |event, index|
      event.update_column(:register_number, index + 1)
    end
  end
end
