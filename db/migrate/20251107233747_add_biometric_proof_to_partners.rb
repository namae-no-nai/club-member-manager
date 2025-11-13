class AddBiometricProofToPartners < ActiveRecord::Migration[8.0]
  def change
    add_column :partners, :biometric_proof, :string
  end
end
