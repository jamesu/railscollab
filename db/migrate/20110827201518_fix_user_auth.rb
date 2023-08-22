class FixUserAuth < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :remember
    remove_column :users, :remember_expires_at
    add_column :users, :remember_token, :string, :limit => 40
    add_column :users, :remember_token_expires_at, :datetime
  end

  def down
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
    add_column :users, :remember, :string
    add_column :users, :remember_expires_at, :datetime
  end
end
