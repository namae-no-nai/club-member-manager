class Weapon < ApplicationRecord
  validates :caliber, presence: true
  validates :category, presence: true
  validates :sigma, presence: true

  has_many :events
end
