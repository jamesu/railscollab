class FixMilestoneObj < ActiveRecord::Migration[4.2]
  def self.up
    change_column :project_task_lists, :milestone_id,  :integer, :default => nil,   :null => true
    change_column :project_messages, :milestone_id,    :integer, :default => nil,   :null => true
  end

  def self.down
    change_column :project_task_lists, :milestone_id,  :integer, :default => 0,   :null => false
    change_column :project_messages, :milestone_id,    :integer, :default => 0,   :null => false
  end
end
