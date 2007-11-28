class MoreData < ActiveRecord::Migration
  def self.up
  	# Firstly, ProjectFile needs a comments_count!
    add_column :project_files, "comments_count",			:integer, :default => 0
    
    ProjectFile.find(:all).each do |obj|
    	obj.update_attribute :comments_count, obj.comments.length
    end
    
    # Secondly, we could do with some more indexes
    add_index "searchable_objects", ["rel_object_id", "rel_object_type"]
    
    # And how about a time tracking option for the task list?
    add_column :project_files, "can_time_track",			:boolean, :default => false, :null => false
  end

  def self.down
    remove_column :project_files, "comments_count"
    remove_index "searchable_objects", :column => ["rel_object_id", "rel_object_type"]
    remove_column :project_files, "can_time_track"
  end
end
