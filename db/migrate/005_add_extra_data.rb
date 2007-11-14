class AddExtraData < ActiveRecord::Migration
  def self.up
    create_table :project_message_categories do |t|
    	t.column "project_id",				:integer, :limit => 10, :null => false
    	t.column "name",					:string,  :limit => 50, :default => "", :null => false
    	t.column "project_messages_count",	:integer, :default => 0
    end
    
    add_column :project_messages, "category_id",			:integer, :limit => 5, :null => false
    
    # Counter caches
    add_column :project_messages, "comments_count",			:integer, :default => 0
    add_column :project_messages, "attached_files_count",	:integer, :default => 0
    add_column :comments, "attached_files_count",			:integer, :default => 0
    add_column :project_folders, "project_files_count",		:integer, :default => 0
    
    # Useful extra fields
    add_column :users, "office_number_ext",					:string, :limit => 5
    add_column :project_companies, "can_view_private",		:boolean, :default => false, :null => false
  end

  def self.down
    drop_table :project_message_categories
    remove_column :project_messages, "category_id"
    
    # Counter caches
    remove_column :project_messages, "comments_count"
    remove_column :project_messages, "attached_files_count"
    remove_column :comments, "attached_files_count"
    remove_column :project_folders, "project_files_count"
    
    # Useful extra fields
    remove_column :users, "office_number_ext"
    remove_column :project_companies, "can_view_private"
  end
end
