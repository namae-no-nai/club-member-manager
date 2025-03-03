class Weapon < ApplicationRecord
  validates :caliber, :category, :sigma, presence: true

  has_many :events
end
