class AddNicknameToCredentials < ActiveRecord::Migration[8.0]
  def change
    add_column :credentials, :nickname, :string
  end
end
