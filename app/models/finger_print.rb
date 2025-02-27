class FingerPrint < ApplicationRecord
  belongs_to :partner

  validates :credentials, presence: true
  validates :description, presence: true
end
