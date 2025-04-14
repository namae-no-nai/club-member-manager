class ChangeBoreTypeToIntegerInWeapons < ActiveRecord::Migration[6.1]
  def change
    change_column :weapons, :bore_type, :integer, using: 'bore_type::integer'
  end
end
