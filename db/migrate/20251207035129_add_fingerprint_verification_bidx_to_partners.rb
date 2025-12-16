class AddFingerprintVerificationBidxToPartners < ActiveRecord::Migration[8.0]
  def change
    add_column :partners, :fingerprint_verification_bidx, :string
    add_index :partners, :fingerprint_verification_bidx
  end
end
