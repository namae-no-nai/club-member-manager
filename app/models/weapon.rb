class Weapon < ApplicationRecord
  validates :caliber, :category, :sigma, presence:, :partner_id true

  has_many :events
  belongs_to :partner

  def friendly_name
    "#{category} / #{caliber} / #{sigma}"
  end
end
