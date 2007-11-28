class RailsFixup < ActiveRecord::Migration
  @@bad_tables = [:application_logs, :attached_files, :comments, :searchable_objects, :tags]
  @@bad_plurals = {
  	# More or less the potentially important stuff
  	:AttachedFiles => 'AttachedFile',
  	:Comments => 'Comment',
  	:Companies => 'Company',
  	:Categories => 'Category',
  	:ConfigOptions => 'ConfigOption',
  	:FileTypes => 'FileType',
  	:MessageSubscriptions => 'MessageSubscription',
  	:ProjectCompanies => 'ProjectCompany',
  	:Projects => 'Project',
  	:ProjectFiles => 'ProjectFile',
  	:ProjectFolders => 'ProjectFolder',
  	:ProjectForms => 'ProjectForm',
  	:ProjectMessages => 'ProjectMessage',
  	:ProjectMilestones => 'ProjectMilestone',
  	:ProjectTasks => 'ProjectTask',
  	:ProjectTaskLists => 'ProjectTaskList',
  	:ProjectTimes => 'ProjectTime',
  	:ProjectUser => 'ProjectUsers',
  	:Tags => 'Tag',
  	:Users => 'User'
  }
  
  def self.up
    remove_index :comments, :column => ["rel_object_id", "rel_object_manager"]
    remove_index :tags, :column => ["rel_object_id", "rel_object_manager"]
    
  	for bad_table in @@bad_tables
  	  rename_column bad_table, "rel_object_manager", "rel_object_type"
  	end
  	
    add_index :comments, ["rel_object_id", "rel_object_type"]
    add_index :tags, ["rel_object_id", "rel_object_type"]

    # Good naming conventions
    remove_index :project_time, :column => ["project_id"]
    remove_index :project_time, :column => ["done_date"]
    remove_index :project_time, :column => ["created_on"]
    
    rename_table :project_time, :project_times

	# Times should be nullable
	[ :comments, 
	  :companies, 
	  :users, 
	  :project_file_revisions, 
	  :project_files, 
	  :project_forms, 
	  :project_messages, 
	  :project_milestones, 
	  :project_task_lists,
	  :project_tasks,
	  :project_times,
	  :projects ].each do 
	  |tbl|
	  change_column tbl, :updated_on, :datetime, :default => nil, :null => true
  	end
    
    add_index :project_times, ["project_id"]
    add_index :project_times, ["done_date"]
    add_index :project_times, ["created_on"]

	change_column :project_milestones, :due_date, :datetime, :default => nil, :null => true
	change_column :project_tasks, :completed_on, :datetime, :default => nil, :null => true
	change_column :project_task_lists, :completed_on, :datetime, :default => nil, :null => true
	change_column :project_times, :done_date, :datetime, :default => nil, :null => true
	change_column :project_files, :expiration_time, :datetime, :default => nil, :null => true
    change_column :projects, :completed_on, :datetime, :default => nil, :null => true
    change_column :project_milestones, :completed_on, :datetime, :default => nil, :null => true

	change_column :users, :last_login, :datetime, :default => nil, :null => true
	change_column :users, :last_visit, :datetime, :default => nil, :null => true
	change_column :users, :last_activity, :datetime, :default => nil, :null => true

  	# Fix for permissions
  	change_column :project_users, :can_manage_time, :boolean, :default => false, :null => false
  	
    # De-pluralize the object types again
  	for bad_table in @@bad_tables
  	  for bad_plural in @@bad_plurals.keys
  	    ActiveRecord::Base.connection.execute("UPDATE #{bad_table} SET rel_object_type = '#{@@bad_plurals[bad_plural]}' WHERE #{bad_table}.rel_object_type = '#{bad_plural}'")
  	  end
  	end
  	
  	# NULL != 0
  	ActiveRecord::Base.connection.execute("UPDATE companies SET client_of_id = NULL WHERE companies.client_of_id = 0")
  end

  def self.down
    # Pluralize the object types again
  	for bad_table in @@bad_tables
  	  for bad_plural in @@bad_plurals.keys
  	    ActiveRecord::Base.connection.execute("UPDATE #{bad_table} SET rel_object_type = '#{bad_plural}' WHERE #{bad_table}.rel_object_type = '#{@@bad_plurals[bad_plural]}'")
  	  end
  	end
  	
    remove_index :comments, :column => ["rel_object_id", "rel_object_type"]
    remove_index :tags, :column => ["rel_object_id", "rel_object_type"]
    
  	for bad_table in @@bad_tables
  	  rename_column bad_table, "rel_object_type", "rel_object_manager"
  	end
  	
    add_index :comments, ["rel_object_id", "rel_object_manager"]
    add_index :tags, ["rel_object_id", "rel_object_manager"]

        # Times should not be nullable
        [ :comments,
          :companies,
          :users,
          :project_file_revisions,
          :project_files,
          :project_forms,
          :project_messages,
          :project_milestones,
          :project_task_lists,
          :project_tasks,
          :project_times,
          :projects ].each do
          |tbl|
          change_column tbl, :updated_on, :datetime, :default => nil, :null => false
        end

        change_column :project_milestones, :due_date, :datetime, :default => nil, :null => false
        change_column :project_tasks, :completed_on, :datetime, :default => nil, :null => false
        change_column :project_task_lists, :completed_on, :datetime, :default => nil, :null => false
        change_column :project_times, :done_date, :datetime, :default => nil, :null => false
        change_column :project_files, :expiration_time, :datetime, :default => nil, :null => false
        change_column :projects, :completed_on, :datetime, :default => nil, :null => false

        change_column :users, :last_login, :datetime, :default => nil, :null => false
        change_column :users, :last_visit, :datetime, :default => nil, :null => false
        change_column :users, :last_activity, :datetime, :default => nil, :null => false
    
  	# Fix for permissions
  	change_column :project_users, :can_manage_time, :boolean, :default => false, :null => false
  	
  	# Bad naming conventions
    remove_index :project_times, ["project_id"]
    remove_index :project_times, ["done_date"]
    remove_index :project_times, ["created_on"]
    
    rename_table :project_times, :project_time
  	
    add_index :project_time, ["project_id"]
    add_index :project_time, ["done_date"]
    add_index :project_time, ["created_on"]
  end
end
