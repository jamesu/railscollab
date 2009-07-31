class AddEstimatedHoursToTasks < ActiveRecord::Migration
  def self.up
    add_column :project_tasks, :estimated_hours, :float
  end

  def self.down
    remove_column :project_tasks, :estimated_hours
  end
end
