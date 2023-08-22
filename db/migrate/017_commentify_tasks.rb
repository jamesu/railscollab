class CommentifyTasks < ActiveRecord::Migration[4.2]
  def self.up
    add_column 'project_tasks', 'comments_count', :integer, :default => 0
  end

  def self.down
    remove_column 'project_tasks', 'comments_count'
  end
end