class OriginalSchema < ActiveRecord::Migration
  def self.up
	  create_table :administration_tools do |t|
	    t.column "name",       :string,  :limit => 50, :default => "", :null => false
	    t.column "controller", :string,  :limit => 50, :default => "", :null => false
	    t.column "action",     :string,  :limit => 50, :default => "", :null => false
	    t.column "order",      :integer, :limit => 3,  :default => 0,  :null => false
	  end
	
	  add_index :administration_tools, ["name"], :unique => true
	
	  create_table :application_logs do |t|
	    t.column "taken_by_id",        :integer,  :limit => 10
	    t.column "project_id",         :integer,  :limit => 10,                                             :default => 0,     :null => false
	    t.column "rel_object_id",      :integer,  :limit => 10,                                             :default => 0,     :null => false
	    t.column "object_name",        :text
	    t.column "rel_object_manager", :string,   :limit => 50,                                             :default => "",    :null => false
	    t.column "created_on",         :datetime,                                                                              :null => false
	    t.column "created_by_id",      :integer,  :limit => 10
	    t.column "action",             :enum,     :limit => [:upload, :open, :close, :delete, :edit, :add]
	    t.column "is_private",         :boolean,                                                            :default => false, :null => false
	    t.column "is_silent",          :boolean,                                                            :default => false, :null => false
	  end
	
	  add_index :application_logs, ["created_on"]
	  add_index :application_logs, ["project_id"]
	
	  create_table :attached_files, :id => false do |t|
	    t.column "rel_object_manager", :string,   :limit => 50, :default => "", :null => false
	    t.column "rel_object_id",      :integer,  :limit => 10, :default => 0,  :null => false
	    t.column "file_id",            :integer,  :limit => 10, :default => 0,  :null => false
	    t.column "created_on",         :datetime,                               :null => false
	    t.column "created_by_id",      :integer,  :limit => 10
	  end
	
	  create_table :comments do |t|
	    t.column "rel_object_id",      :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "rel_object_manager", :string,   :limit => 30,  :default => "",    :null => false
	    t.column "text",               :text
	    t.column "is_private",         :boolean,                 :default => false, :null => false
	    t.column "is_anonymous",       :boolean,                 :default => false, :null => false
	    t.column "author_name",        :string,   :limit => 50
	    t.column "author_email",       :string,   :limit => 100
	    t.column "author_homepage",    :string,   :limit => 100, :default => "",    :null => false
	    t.column "created_on",         :datetime,                                   :null => false
	    t.column "created_by_id",      :integer,  :limit => 10
	    t.column "updated_on",         :datetime,                                   :null => false
	    t.column "updated_by_id",      :integer,  :limit => 10
	  end
	
	  add_index :comments, ["rel_object_id", "rel_object_manager"]
	  add_index :comments, ["created_on"]
	
	  create_table :companies do |t|
	    t.column "client_of_id",      :integer,  :limit => 5
	    t.column "name",              :string,   :limit => 50
	    t.column "email",             :string,   :limit => 100
	    t.column "homepage",          :string,   :limit => 100
	    t.column "address",           :string,   :limit => 100
	    t.column "address2",          :string,   :limit => 100
	    t.column "city",              :string,   :limit => 50
	    t.column "state",             :string,   :limit => 50
	    t.column "zipcode",           :string,   :limit => 30
	    t.column "country",           :string,   :limit => 10
	    t.column "phone_number",      :string,   :limit => 30
	    t.column "fax_number",        :string,   :limit => 30
	    t.column "logo_file",         :string,   :limit => 44
	    t.column "timezone",          :float,    :limit => 2,   :default => 0.0,   :null => false
	    t.column "hide_welcome_info", :boolean,                 :default => false, :null => false
	    t.column "created_on",        :datetime,                                   :null => false
	    t.column "created_by_id",     :integer,  :limit => 10
	    t.column "updated_on",        :datetime,                                   :null => false
	    t.column "updated_by_id",     :integer,  :limit => 10
	  end
	
	  add_index :companies, ["created_on"]
	  add_index :companies, ["client_of_id"]
	
	  create_table :config_categories do |t|
	    t.column "name",           :string,  :limit => 50, :default => "",    :null => false
	    t.column "is_system",      :boolean,               :default => false, :null => false
	    t.column "category_order", :integer, :limit => 3,  :default => 0,     :null => false
	  end
	
	  add_index :config_categories, ["name"], :unique => true
	  add_index :config_categories, ["category_order"]
	
	  create_table :config_options do |t|
	    t.column "category_name",        :string,  :limit => 30, :default => "",    :null => false
	    t.column "name",                 :string,  :limit => 50, :default => "",    :null => false
	    t.column "value",                :text
	    t.column "config_handler_class", :string,  :limit => 50, :default => "",    :null => false
	    t.column "is_system",            :boolean,               :default => false, :null => false
	    t.column "option_order",         :integer, :limit => 5,  :default => 0,     :null => false
	    t.column "dev_comment",          :string
	  end
	
	  add_index :config_options, ["name"], :unique => true
	  add_index :config_options, ["option_order"]
	  add_index :config_options, ["category_name"]
	
	  create_table :file_repo do |t|
	    t.column "content", :binary,                :default => "", :null => false
	    t.column "order",   :integer, :limit => 10, :default => 0,  :null => false
	  end
	
	  add_index :file_repo, ["order"]
	
	  create_table :file_repo_attributes do |t|
	    t.column "attribute", :string, :limit => 50, :default => "", :null => false
	    t.column "value",     :text,                 :default => "", :null => false
	  end
	
	  create_table :file_types do |t|
	    t.column "extension",     :string,  :limit => 10, :default => "",    :null => false
	    t.column "icon",          :string,  :limit => 30, :default => "",    :null => false
	    t.column "is_searchable", :boolean,               :default => false, :null => false
	    t.column "is_image",      :boolean,               :default => false, :null => false
	  end
	
	  add_index :file_types, ["extension"], :unique => true
	
	  create_table :im_types do |t|
	    t.column "name", :string, :limit => 30, :default => "", :null => false
	    t.column "icon", :string, :limit => 30, :default => "", :null => false
	  end
	
	  create_table :message_subscriptions, :id => false do |t|
	    t.column "message_id", :integer, :limit => 10, :default => 0, :null => false
	    t.column "user_id",    :integer, :limit => 10, :default => 0, :null => false
	  end
	
	  create_table :project_companies, :id => false do |t|
	    t.column "project_id", :integer, :limit => 10, :default => 0, :null => false
	    t.column "company_id", :integer, :limit => 5,  :default => 0, :null => false
	  end
	
	  create_table :project_file_revisions do |t|
	    t.column "file_id",         :integer,  :limit => 10, :default => 0,  :null => false
	    t.column "file_type_id",    :integer,  :limit => 5,  :default => 0,  :null => false
	    t.column "repository_id",   :string,   :limit => 40, :default => "", :null => false
	    t.column "thumb_filename",  :string,   :limit => 44
	    t.column "revision_number", :integer,  :limit => 10, :default => 0,  :null => false
	    t.column "comment",         :text
	    t.column "type_string",     :string,   :limit => 50, :default => "", :null => false
	    t.column "filesize",        :integer,  :limit => 10, :default => 0,  :null => false
	    t.column "created_on",      :datetime,                               :null => false
	    t.column "created_by_id",   :integer,  :limit => 10
	    t.column "updated_on",      :datetime,                               :null => false
	    t.column "updated_by_id",   :integer,  :limit => 10
	  end
	
	  add_index :project_file_revisions, ["file_id"]
	  add_index :project_file_revisions, ["updated_on"]
	  add_index :project_file_revisions, ["revision_number"]
	
	  create_table :project_files do |t|
	    t.column "project_id",                 :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "folder_id",                  :integer,  :limit => 5,   :default => 0,     :null => false
	    t.column "filename",                   :string,   :limit => 100, :default => "",    :null => false
	    t.column "description",                :text
	    t.column "is_private",                 :boolean,                 :default => false, :null => false
	    t.column "is_important",               :boolean,                 :default => false, :null => false
	    t.column "is_locked",                  :boolean,                 :default => false, :null => false
	    t.column "is_visible",                 :boolean,                 :default => false, :null => false
	    t.column "expiration_time",            :datetime,                                   :null => false
	    t.column "comments_enabled",           :boolean,                 :default => false, :null => false
	    t.column "anonymous_comments_enabled", :boolean,                 :default => false, :null => false
	    t.column "created_on",                 :datetime,                                   :null => false
	    t.column "created_by_id",              :integer,  :limit => 10,  :default => 0
	    t.column "updated_on",                 :datetime,                                   :null => false
	    t.column "updated_by_id",              :integer,  :limit => 10,  :default => 0
	  end
	
	  add_index :project_files, ["project_id"]
	
	  create_table :project_folders do |t|
	    t.column "project_id", :integer, :limit => 10, :default => 0,  :null => false
	    t.column "name",       :string,  :limit => 50, :default => "", :null => false
	  end
	
	  add_index :project_folders, ["project_id", "name"], :unique => true
	
	  create_table :project_forms do |t|
	    t.column "project_id",      :integer,  :limit => 10,                        :default => 0,            :null => false
	    t.column "name",            :string,   :limit => 50,                        :default => "",           :null => false
	    t.column "description",     :text,                                          :default => "",           :null => false
	    t.column "success_message", :text,                                          :default => "",           :null => false
	    t.column "action",          :enum,     :limit => [:add_comment, :add_task], :default => :add_comment, :null => false
	    t.column "in_object_id",    :integer,  :limit => 10,                        :default => 0,            :null => false
	    t.column "created_on",      :datetime
	    t.column "created_by_id",   :integer,  :limit => 10,                        :default => 0,            :null => false
	    t.column "updated_on",      :datetime,                                                                :null => false
	    t.column "updated_by_id",   :integer,  :limit => 10,                        :default => 0,            :null => false
	    t.column "is_visible",      :boolean,                                       :default => false,        :null => false
	    t.column "is_enabled",      :boolean,                                       :default => false,        :null => false
	    t.column "order",           :integer,  :limit => 6,                         :default => 0,            :null => false
	  end
	
	  create_table :project_messages do |t|
	    t.column "milestone_id",               :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "project_id",                 :integer,  :limit => 10
	    t.column "title",                      :string,   :limit => 100
	    t.column "text",                       :text
	    t.column "additional_text",            :text
	    t.column "is_important",               :boolean,                 :default => false, :null => false
	    t.column "is_private",                 :boolean,                 :default => false, :null => false
	    t.column "comments_enabled",           :boolean,                 :default => false, :null => false
	    t.column "anonymous_comments_enabled", :boolean,                 :default => false, :null => false
	    t.column "created_on",                 :datetime,                                   :null => false
	    t.column "created_by_id",              :integer,  :limit => 10
	    t.column "updated_on",                 :datetime,                                   :null => false
	    t.column "updated_by_id",              :integer,  :limit => 10
	  end
	
	  add_index :project_messages, ["milestone_id"]
	  add_index :project_messages, ["project_id"]
	  add_index :project_messages, ["created_on"]
	
	  create_table :project_milestones do |t|
	    t.column "project_id",             :integer,  :limit => 10
	    t.column "name",                   :string,   :limit => 100
	    t.column "description",            :text
	    t.column "due_date",               :datetime,                                   :null => false
	    t.column "assigned_to_company_id", :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "assigned_to_user_id",    :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "is_private",             :boolean,                 :default => false, :null => false
	    t.column "completed_on",           :datetime,                                   :null => false
	    t.column "completed_by_id",        :integer,  :limit => 10
	    t.column "created_on",             :datetime,                                   :null => false
	    t.column "created_by_id",          :integer,  :limit => 10
	    t.column "updated_on",             :datetime,                                   :null => false
	    t.column "updated_by_id",          :integer,  :limit => 10
	  end
	
	  add_index :project_milestones, ["project_id"]
	  add_index :project_milestones, ["due_date"]
	  add_index :project_milestones, ["completed_on"]
	  add_index :project_milestones, ["created_on"]
	
	  create_table :project_task_lists do |t|
	    t.column "priority",        :integer
	    t.column "milestone_id",    :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "project_id",      :integer,  :limit => 10
	    t.column "name",            :string,   :limit => 100
	    t.column "description",     :text
	    t.column "is_private",      :boolean,                 :default => false, :null => false
	    t.column "completed_on",    :datetime,                                   :null => false
	    t.column "completed_by_id", :integer,  :limit => 10
	    t.column "created_on",      :datetime
	    t.column "created_by_id",   :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "updated_on",      :datetime
	    t.column "updated_by_id",   :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "order",           :integer,  :limit => 3,   :default => 0,     :null => false
	  end
	
	  add_index :project_task_lists, ["milestone_id"]
	  add_index :project_task_lists, ["project_id"]
	  add_index :project_task_lists, ["completed_on"]
	  add_index :project_task_lists, ["created_on"]
	
	  create_table :project_tasks do |t|
	    t.column "task_list_id",           :integer,  :limit => 10
	    t.column "text",                   :text
	    t.column "assigned_to_company_id", :integer,  :limit => 5
	    t.column "assigned_to_user_id",    :integer,  :limit => 10
	    t.column "completed_on",           :datetime,                              :null => false
	    t.column "completed_by_id",        :integer,  :limit => 10
	    t.column "created_on",             :datetime,                              :null => false
	    t.column "created_by_id",          :integer,  :limit => 10
	    t.column "updated_on",             :datetime,                              :null => false
	    t.column "updated_by_id",          :integer,  :limit => 10
	    t.column "order",                  :integer,  :limit => 10, :default => 0, :null => false
	  end
	
	  add_index :project_tasks, ["task_list_id"]
	  add_index :project_tasks, ["completed_on"]
	  add_index :project_tasks, ["created_on"]
	  add_index :project_tasks, ["order"]
	
	  create_table :project_users, :id => false do |t|
	    t.column "project_id",            :integer,  :limit => 10, :default => 0,     :null => false
	    t.column "user_id",               :integer,  :limit => 10, :default => 0,     :null => false
	    t.column "created_on",            :datetime
	    t.column "created_by_id",         :integer,  :limit => 10, :default => 0,     :null => false
	    t.column "can_manage_messages",   :boolean,                :default => false
	    t.column "can_manage_tasks",      :boolean,                :default => false
	    t.column "can_manage_milestones", :boolean,                :default => false
	    t.column "can_upload_files",      :boolean,                :default => false
	    t.column "can_manage_files",      :boolean,                :default => false
	    t.column "can_assign_to_owners",  :boolean,                :default => false, :null => false
	    t.column "can_assign_to_other",   :boolean,                :default => false, :null => false
	  end
	
	  create_table :projects do |t|
	    t.column "priority",                     :integer
	    t.column "name",                         :string,   :limit => 50
	    t.column "description",                  :text
	    t.column "show_description_in_overview", :boolean,                :default => false, :null => false
	    t.column "completed_on",                 :datetime,                                  :null => false
	    t.column "completed_by_id",              :integer
	    t.column "created_on",                   :datetime,                                  :null => false
	    t.column "created_by_id",                :integer,  :limit => 10
	    t.column "updated_on",                   :datetime,                                  :null => false
	    t.column "updated_by_id",                :integer,  :limit => 10
	  end
	
	  add_index :projects, ["completed_on"]
	
	  create_table :searchable_objects, :id => false do |t|
	    t.column "rel_object_manager", :string,  :limit => 50, :default => "",    :null => false
	    t.column "rel_object_id",      :integer, :limit => 10, :default => 0,     :null => false
	    t.column "column_name",        :string,  :limit => 50, :default => "",    :null => false
	    t.column "content",            :text,                  :default => "",    :null => false
	    t.column "project_id",         :integer, :limit => 10, :default => 0,     :null => false
	    t.column "is_private",         :boolean,               :default => false, :null => false
	  end
	
	  add_index :searchable_objects, ["project_id"]
	  #add_index :searchable_objects, ["content"], :name => "content"
	
	  create_table :tags do |t|
	    t.column "project_id",         :integer,  :limit => 10, :default => 0,     :null => false
	    t.column "tag",                :string,   :limit => 30, :default => "",    :null => false
	    t.column "rel_object_id",      :integer,  :limit => 10, :default => 0,     :null => false
	    t.column "rel_object_manager", :string,   :limit => 50, :default => "",    :null => false
	    t.column "created_on",         :datetime
	    t.column "created_by_id",      :integer,  :limit => 10, :default => 0,     :null => false
	    t.column "is_private",         :boolean,                :default => false, :null => false
	  end
	
	  add_index :tags, ["project_id"]
	  add_index :tags, ["tag"]
	  add_index :tags, ["rel_object_id", "rel_object_manager"]
	
	  create_table :user_im_values, :id => false do |t|
	    t.column "user_id",    :integer, :limit => 10, :default => 0,     :null => false
	    t.column "im_type_id", :integer, :limit => 3,  :default => 0,     :null => false
	    t.column "value",      :string,  :limit => 50, :default => "",    :null => false
	    t.column "is_default", :boolean,               :default => false, :null => false
	  end
	
	  add_index :user_im_values, ["is_default"]
	
	  create_table :users do |t|
	    t.column "company_id",    :integer,  :limit => 5,   :default => 0,     :null => false
	    t.column "username",      :string,   :limit => 50,  :default => "",    :null => false
	    t.column "email",         :string,   :limit => 100
	    t.column "token",         :string,   :limit => 40,  :default => "",    :null => false
	    t.column "salt",          :string,   :limit => 13,  :default => "",    :null => false
	    t.column "twister",       :string,   :limit => 10,  :default => "",    :null => false
	    t.column "display_name",  :string,   :limit => 50
	    t.column "title",         :string,   :limit => 30
	    t.column "avatar_file",   :string,   :limit => 44
	    t.column "office_number", :string,   :limit => 20
	    t.column "fax_number",    :string,   :limit => 20
	    t.column "mobile_number", :string,   :limit => 20
	    t.column "home_number",   :string,   :limit => 20
	    t.column "timezone",      :float,    :limit => 2,   :default => 0.0,   :null => false
	    t.column "created_on",    :datetime,                                   :null => false
	    t.column "created_by_id", :integer,  :limit => 10
	    t.column "updated_on",    :datetime,                                   :null => false
	    t.column "last_login",    :datetime,                                   :null => false
	    t.column "last_visit",    :datetime,                                   :null => false
	    t.column "last_activity", :datetime,                                   :null => false
	    t.column "is_admin",      :boolean
	    t.column "auto_assign",   :boolean,                 :default => false, :null => false
	  end
	
	  add_index :users, ["username"], :unique => true
	  add_index :users, ["email"], :unique => true
	  add_index :users, ["last_visit"]
	  add_index :users, ["company_id"]
	  add_index :users, ["last_login"]
  end

  def self.down
    drop_table :administration_tools
    drop_table :application_logs
    drop_table :attached_files
  	drop_table :comments
  	drop_table :companies
  	drop_table :config_categories
  	drop_table :config_options
  	drop_table :file_repo
  	drop_table :file_repo_attributes
  	drop_table :file_types
  	drop_table :im_types
  	drop_table :message_subscriptions
  	drop_table :project_companies
  	drop_table :project_file_revisions
  	drop_table :project_files
  	drop_table :project_folders
  	drop_table :project_forms
  	drop_table :project_messages
  	drop_table :project_milestones
  	drop_table :project_task_lists
  	drop_table :project_tasks
  	drop_table :project_users
  	drop_table :projects
  	drop_table :searchable_objects
  	drop_table :tags
  	drop_table :user_im_values
  	drop_table :users
  end
end
