class CleanupBadSchema < ActiveRecord::Migration[4.2]
  
  def self.up
    drop_table "administration_tools"
    drop_table "open_id_authentication_associations"
    drop_table "open_id_authentication_nonces"
    
    rename_table "application_logs", "activities"
    rename_table "project_folders", "folders"
    rename_table "project_message_categories", "categories"
    rename_table "project_messages", "messages"
    rename_table "project_milestones", "milestones"
    rename_table "project_task_lists", "task_lists"
    rename_table "project_tasks", "tasks"
    rename_table "project_times", "time_records"
    rename_table "project_users", "people"
    
    rename_column "categories", "project_messages_count", "messages_count"
    
    # Missing PK's
    add_column :people, :id, :primary_key
    add_column :user_im_values, :id, :primary_key
    
    remove_column "users", "identity_url"
    
    # Rename all rel_objects
    ['activities', 'attached_files', 'comments', 'tags'].each do |table_name|
      [
        ['ApplicationLog', 'Activity'],
        ['ProjectMessageCategory', 'Category'],
        ['ProjectFolder', 'Folder'],
        ['ProjectMessage', 'Message'],
        ['ProjectMilestone', 'Milestone'],
        ['ProjectTask', 'Task'],
        ['ProjectTaskList', 'TaskList'],
        ['ProjectTime', 'TimeRecord']
      ].each do |mapping|
        src_type = mapping[1]
        dest_type = mapping[0]
        Project.connection.execute("UPDATE #{ActiveRecord::Base.connection.quote_table_name(table_name)} SET rel_object_type = '#{src_type}' WHERE rel_object_type = '#{dest_type}'")
      end
    end
       
    # Taken by? wtf?!
    remove_column "activities", "taken_by_id"
    
    # Fix for schema
    change_column "projects", "priority", :integer, :null => true
    
    # Combine additional text into message text
    Message.all.each {|m| m.update_attribute(:text, m.text+"\n"+m.additional_text) }
    remove_column "messages", "additional_text"
  end

  # its a one-way street
  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
