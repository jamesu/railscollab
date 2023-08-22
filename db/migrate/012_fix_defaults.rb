class FixDefaults < ActiveRecord::Migration[4.2]
  def self.up
    change_column :users, 'is_admin', :boolean, :default => false, :null => false
  end

  def self.down
    # Not required
  end
end
