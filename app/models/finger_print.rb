class FingerPrint < ApplicationRecord
  belongs_to :partner

  validates :credentials, :description, presence: true
end
