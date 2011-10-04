class CommentFix < ActiveRecord::Base
  set_table_name 'comments'
  belongs_to :rel_object, :polymorphic => true
end

class TaskFix < ActiveRecord::Base
  set_table_name 'tasks'
  belongs_to :task_list
end

class FileRevisionFix < ActiveRecord::Base
  set_table_name 'project_file_revisions'
  belongs_to :project_file
end

class ProjectsOnObjects < ActiveRecord::Migration
  def up
    add_column :comments, :project_id, :integer
    add_index :comments, :project_id
    add_column :tasks, :project_id, :integer
    add_index :tasks, :project_id
    add_column :project_file_revisions, :project_id, :integer
    add_index :project_file_revisions, :project_id
    
    # Update all comments
    CommentFix.all.each do |comment|
      comment.update_attribute :project_id, comment.rel_object.project_id
    end
    
    # Update all tasks
    TaskFix.all.each do |task|
      task.update_attribute :project_id, task.task_list.project_id
    end
    
    # Update all file revisions
    FileRevisionFix.all.each do |file|
      file.update_attribute :project_id, file.project_file.project_id
    end
  end

  def down
    remove_column :comments, :project_id
    remove_column :tasks, :project_id
    remove_column :project_file_revisions, :project_id
  end
end
