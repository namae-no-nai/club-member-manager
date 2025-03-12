class Weapon < ApplicationRecord
  validates :caliber, :category, :sigma, presence: true

  has_many :events

  def friendly_name
    "#{category} / #{caliber} / #{sigma}"
  end
end
