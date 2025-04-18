class AddArchivedFieldsToWeapons < ActiveRecord::Migration[8.0]
  def change
    add_column :weapons, :archived_at, :datetime
    add_column :weapons, :archived_reason, :string
  end
end
