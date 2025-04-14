class ChangeAuthorizedUseToIntegerInWeapons < ActiveRecord::Migration[6.1]
  def change
    change_column :weapons, :authorized_use, :integer, using: 'authorized_use::integer'
  end
end
