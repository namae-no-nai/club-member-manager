class Weapon < ApplicationRecord
  validates :caliber, :category, :sigma, :partner_id ,presence: true

  has_many :events
  belongs_to :partner


  scope :available, ->(partner) { where(partner_id: [partner.id, Partner.club.id]) }

  def to_h
    {id:, friendly_name:}
  end

  def friendly_name
    "#{category} - #{caliber} - #{sigma}"
  end
end
