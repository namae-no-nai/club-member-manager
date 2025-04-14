class ChangeWeaponTypeToIntegerInWeapons < ActiveRecord::Migration[6.1]
  def change
    change_column :weapons, :weapon_type, :integer, using: 'weapon_type::integer'
  end
end
