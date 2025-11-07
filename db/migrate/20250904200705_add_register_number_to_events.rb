class AddRegisterNumberToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :register_number, :integer
  end
end
