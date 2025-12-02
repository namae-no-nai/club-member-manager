class AddFingerprintVerificationToPartners < ActiveRecord::Migration[8.0]
  def change
    add_column :partners, :fingerprint_verification_ciphertext, :text
  end
end

