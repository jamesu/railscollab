class AddRememberTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :remember, :string
    add_column :users, :remember_expires_at, :datetime
  end

  def self.down
    remove_column :users, :remember_expires_at
    remove_column :users, :remember
  end
end
