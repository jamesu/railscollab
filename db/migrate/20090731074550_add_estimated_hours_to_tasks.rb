class AddEstimatedHoursToTasks < ActiveRecord::Migration[4.2]
  def self.up
    add_column :project_tasks, :estimated_hours, :float
  end

  def self.down
    remove_column :project_tasks, :estimated_hours
  end
end
