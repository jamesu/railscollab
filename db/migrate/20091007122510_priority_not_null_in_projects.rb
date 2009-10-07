class PriorityNotNullInProjects < ActiveRecord::Migration
  def self.up
    change_column_null :projects, :priority, false, 0
  end

  def self.down
    change_column_null :projects, :priority, true
  end
end
