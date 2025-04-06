class Weapon < ApplicationRecord
  validates :partner_id, :sigma, :serial_number, :weapon_type, :brand, :caliber,
            :model, :action, :bore_type, :authorized_use, presence: true

  has_many :events
  belongs_to :partner

  #validation sigma ^[A-Z0-9]{9,12}$


  scope :available, ->(partner) {
    where(partner_id: [ partner.id, Partner.club.id ]) }

  def to_h
    { id:, friendly_name: }
  end

  def friendly_name
    "#{weapon_type} - #{caliber} - #{brand} - #{model}"
  end
end
