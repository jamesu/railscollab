class BaseSchema < ActiveRecord::Migration[4.2]
  def self.up
    create_table "administration_tools", :force => true do |t|
      t.string  "name",       :limit => 50, :default => "", :null => false
      t.string  "controller", :limit => 50, :default => "", :null => false
      t.string  "action",     :limit => 50, :default => "", :null => false
      t.integer "order",      :limit => 3,  :default => 0,  :null => false
    end
  
    add_index "administration_tools", ["name"], :name => "index_administration_tools_on_name", :unique => true
  
    create_table "application_logs", :force => true do |t|
      t.integer  "taken_by_id"
      t.integer  "project_id",                    :default => 0,     :null => false
      t.integer  "rel_object_id",                 :default => 0,     :null => false
      t.text     "object_name"
      t.string   "rel_object_type", :limit => 50, :default => "",    :null => false
      t.datetime "created_on",                                       :null => false
      t.integer  "created_by_id"
      t.boolean  "is_private",                    :default => false, :null => false
      t.boolean  "is_silent",                     :default => false, :null => false
      t.integer  "action_id",       :limit => 1
    end
  
    add_index "application_logs", ["created_on"], :name => "index_application_logs_on_created_on"
    add_index "application_logs", ["project_id"], :name => "index_application_logs_on_project_id"
  
    create_table "attached_files", :id => false, :force => true do |t|
      t.string   "rel_object_type", :limit => 50, :default => "", :null => false
      t.integer  "rel_object_id",                 :default => 0,  :null => false
      t.integer  "file_id",                       :default => 0,  :null => false
      t.datetime "created_on",                                    :null => false
      t.integer  "created_by_id"
    end
  
    create_table "comments", :force => true do |t|
      t.integer  "rel_object_id",                       :default => 0,     :null => false
      t.string   "rel_object_type",      :limit => 30,  :default => "",    :null => false
      t.text     "text"
      t.boolean  "is_private",                          :default => false, :null => false
      t.boolean  "is_anonymous",                        :default => false, :null => false
      t.string   "author_name",          :limit => 50
      t.string   "author_email",         :limit => 100
      t.string   "author_homepage",      :limit => 100, :default => "",    :null => false
      t.datetime "created_on",                                             :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
      t.integer  "attached_files_count",                :default => 0
    end
  
    add_index "comments", ["created_on"], :name => "index_comments_on_created_on"
    add_index "comments", ["rel_object_id", "rel_object_type"], :name => "index_comments_on_rel_object_id_and_rel_object_type"
  
    create_table "companies", :force => true do |t|
      t.integer  "client_of_id",      :limit => 8
      t.string   "name",              :limit => 50
      t.string   "email",             :limit => 100
      t.string   "homepage",          :limit => 100
      t.string   "address",           :limit => 100
      t.string   "address2",          :limit => 100
      t.string   "city",              :limit => 50
      t.string   "state",             :limit => 50
      t.string   "zipcode",           :limit => 30
      t.string   "country",           :limit => 10
      t.string   "phone_number",      :limit => 30
      t.string   "fax_number",        :limit => 30
      t.string   "logo_file",         :limit => 44
      t.float    "timezone",                         :default => 0.0,   :null => false
      t.boolean  "hide_welcome_info",                :default => false, :null => false
      t.datetime "created_on",                                          :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
    end
  
    add_index "companies", ["created_on"], :name => "index_companies_on_created_on"
    add_index "companies", ["client_of_id"], :name => "index_companies_on_client_of_id"
  
    create_table "config_categories", :force => true do |t|
      t.string  "name",           :limit => 50, :default => "",    :null => false
      t.boolean "is_system",                    :default => false, :null => false
      t.integer "category_order", :limit => 3,  :default => 0,     :null => false
    end
  
    add_index "config_categories", ["name"], :name => "index_config_categories_on_name", :unique => true
    add_index "config_categories", ["category_order"], :name => "index_config_categories_on_category_order"
  
    create_table "config_options", :force => true do |t|
      t.string  "category_name",        :limit => 30, :default => "",    :null => false
      t.string  "name",                 :limit => 50, :default => "",    :null => false
      t.text    "value"
      t.string  "config_handler_class", :limit => 50, :default => "",    :null => false
      t.boolean "is_system",                          :default => false, :null => false
      t.integer "option_order",         :limit => 8,  :default => 0,     :null => false
      t.string  "dev_comment"
    end
  
    add_index "config_options", ["name"], :name => "index_config_options_on_name", :unique => true
    add_index "config_options", ["option_order"], :name => "index_config_options_on_option_order"
    add_index "config_options", ["category_name"], :name => "index_config_options_on_category_name"
  
    create_table "file_repo", :force => true do |t|
      t.binary  "content",                :null => false
      t.integer "order",   :default => 0, :null => false
    end
  
    add_index "file_repo", ["order"], :name => "index_file_repo_on_order"
  
    create_table "file_repo_attributes", :force => true do |t|
      t.string "attribute", :limit => 50, :default => "", :null => false
      t.text   "value",                                   :null => false
    end
  
    create_table "file_types", :force => true do |t|
      t.string  "extension",     :limit => 10, :default => "",    :null => false
      t.string  "icon",          :limit => 30, :default => "",    :null => false
      t.boolean "is_searchable",               :default => false, :null => false
      t.boolean "is_image",                    :default => false, :null => false
    end
  
    add_index "file_types", ["extension"], :name => "index_file_types_on_extension", :unique => true
  
    create_table "im_types", :force => true do |t|
      t.string "name", :limit => 30, :default => "", :null => false
      t.string "icon", :limit => 30, :default => "", :null => false
    end
  
    create_table "message_subscriptions", :id => false, :force => true do |t|
      t.integer "message_id", :default => 0, :null => false
      t.integer "user_id",    :default => 0, :null => false
    end
  
    create_table "open_id_associations", :force => true do |t|
      t.binary  "server_url"
      t.string  "handle"
      t.binary  "secret"
      t.integer "issued"
      t.integer "lifetime"
      t.string  "assoc_type"
    end
  
    create_table "open_id_nonces", :force => true do |t|
      t.string  "nonce"
      t.integer "created"
    end
  
    create_table "open_id_settings", :force => true do |t|
      t.string "setting"
      t.binary "value"
    end
  
    create_table "project_companies", :id => false, :force => true do |t|
      t.integer "project_id",                    :default => 0,     :null => false
      t.integer "company_id",       :limit => 8, :default => 0,     :null => false
      t.boolean "can_view_private",              :default => false, :null => false
    end
  
    create_table "project_file_revisions", :force => true do |t|
      t.integer  "file_id",                       :default => 0,  :null => false
      t.integer  "file_type_id",    :limit => 8,  :default => 0,  :null => false
      t.string   "repository_id",   :limit => 40, :default => "", :null => false
      t.string   "thumb_filename",  :limit => 44
      t.integer  "revision_number",               :default => 0,  :null => false
      t.text     "comment"
      t.string   "type_string",     :limit => 50, :default => "", :null => false
      t.integer  "filesize",                      :default => 0,  :null => false
      t.datetime "created_on",                                    :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
    end
  
    add_index "project_file_revisions", ["file_id"], :name => "index_project_file_revisions_on_file_id"
    add_index "project_file_revisions", ["updated_on"], :name => "index_project_file_revisions_on_updated_on"
    add_index "project_file_revisions", ["revision_number"], :name => "index_project_file_revisions_on_revision_number"
  
    create_table "project_files", :force => true do |t|
      t.integer  "project_id",                                :default => 0,     :null => false
      t.integer  "folder_id",                  :limit => 8,   :default => 0,     :null => false
      t.string   "filename",                   :limit => 100, :default => "",    :null => false
      t.text     "description"
      t.boolean  "is_private",                                :default => false, :null => false
      t.boolean  "is_important",                              :default => false, :null => false
      t.boolean  "is_locked",                                 :default => false, :null => false
      t.boolean  "is_visible",                                :default => false, :null => false
      t.datetime "expiration_time"
      t.boolean  "comments_enabled",                          :default => false, :null => false
      t.boolean  "anonymous_comments_enabled",                :default => false, :null => false
      t.datetime "created_on",                                                   :null => false
      t.integer  "created_by_id",                             :default => 0
      t.datetime "updated_on"
      t.integer  "updated_by_id",                             :default => 0
      t.integer  "comments_count",                            :default => 0
      t.boolean  "can_time_track",                            :default => false, :null => false
    end
  
    add_index "project_files", ["project_id"], :name => "index_project_files_on_project_id"
  
    create_table "project_folders", :force => true do |t|
      t.integer "project_id",                        :default => 0,  :null => false
      t.string  "name",                :limit => 50, :default => "", :null => false
      t.integer "project_files_count",               :default => 0
    end
  
    add_index "project_folders", ["project_id", "name"], :name => "index_project_folders_on_project_id_and_name", :unique => true
  
    create_table "project_forms", :force => true do |t|
      t.integer  "project_id",                    :default => 0,     :null => false
      t.string   "name",            :limit => 50, :default => "",    :null => false
      t.text     "description",                                      :null => false
      t.text     "success_message",                                  :null => false
      t.integer  "in_object_id",                  :default => 0,     :null => false
      t.datetime "created_on"
      t.integer  "created_by_id",                 :default => 0,     :null => false
      t.datetime "updated_on"
      t.integer  "updated_by_id",                 :default => 0,     :null => false
      t.boolean  "is_visible",                    :default => false, :null => false
      t.boolean  "is_enabled",                    :default => false, :null => false
      t.integer  "order",           :limit => 8,  :default => 0,     :null => false
      t.integer  "action_id",       :limit => 1
    end
  
    create_table "project_message_categories", :force => true do |t|
      t.integer "project_id",                                           :null => false
      t.string  "name",                   :limit => 50, :default => "", :null => false
      t.integer "project_messages_count",               :default => 0
    end
  
    create_table "project_messages", :force => true do |t|
      t.integer  "milestone_id",                              :default => 0,     :null => false
      t.integer  "project_id"
      t.string   "title",                      :limit => 100
      t.text     "text"
      t.text     "additional_text"
      t.boolean  "is_important",                              :default => false, :null => false
      t.boolean  "is_private",                                :default => false, :null => false
      t.boolean  "comments_enabled",                          :default => false, :null => false
      t.boolean  "anonymous_comments_enabled",                :default => false, :null => false
      t.datetime "created_on",                                                   :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
      t.integer  "category_id",                :limit => 8,                      :null => false
      t.integer  "comments_count",                            :default => 0
      t.integer  "attached_files_count",                      :default => 0
    end
  
    add_index "project_messages", ["milestone_id"], :name => "index_project_messages_on_milestone_id"
    add_index "project_messages", ["project_id"], :name => "index_project_messages_on_project_id"
    add_index "project_messages", ["created_on"], :name => "index_project_messages_on_created_on"
  
    create_table "project_milestones", :force => true do |t|
      t.integer  "project_id"
      t.string   "name",                   :limit => 100
      t.text     "description"
      t.datetime "due_date"
      t.integer  "assigned_to_company_id",                :default => 0,     :null => false
      t.integer  "assigned_to_user_id",                   :default => 0,     :null => false
      t.boolean  "is_private",                            :default => false, :null => false
      t.datetime "completed_on"
      t.integer  "completed_by_id"
      t.datetime "created_on",                                               :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
    end
  
    add_index "project_milestones", ["project_id"], :name => "index_project_milestones_on_project_id"
    add_index "project_milestones", ["due_date"], :name => "index_project_milestones_on_due_date"
    add_index "project_milestones", ["completed_on"], :name => "index_project_milestones_on_completed_on"
    add_index "project_milestones", ["created_on"], :name => "index_project_milestones_on_created_on"
  
    create_table "project_task_lists", :force => true do |t|
      t.integer  "priority"
      t.integer  "milestone_id",                   :default => 0,     :null => false
      t.integer  "project_id"
      t.string   "name",            :limit => 100
      t.text     "description"
      t.boolean  "is_private",                     :default => false, :null => false
      t.datetime "completed_on"
      t.integer  "completed_by_id"
      t.datetime "created_on"
      t.integer  "created_by_id",                  :default => 0,     :null => false
      t.datetime "updated_on"
      t.integer  "updated_by_id",                  :default => 0,     :null => false
      t.integer  "order",           :limit => 3,   :default => 0,     :null => false
    end
  
    add_index "project_task_lists", ["milestone_id"], :name => "index_project_task_lists_on_milestone_id"
    add_index "project_task_lists", ["project_id"], :name => "index_project_task_lists_on_project_id"
    add_index "project_task_lists", ["completed_on"], :name => "index_project_task_lists_on_completed_on"
    add_index "project_task_lists", ["created_on"], :name => "index_project_task_lists_on_created_on"
  
    create_table "project_tasks", :force => true do |t|
      t.integer  "task_list_id"
      t.text     "text"
      t.integer  "assigned_to_company_id", :limit => 8
      t.integer  "assigned_to_user_id"
      t.datetime "completed_on"
      t.integer  "completed_by_id"
      t.datetime "created_on",                                         :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
      t.integer  "order",                               :default => 0, :null => false
    end
  
    add_index "project_tasks", ["task_list_id"], :name => "index_project_tasks_on_task_list_id"
    add_index "project_tasks", ["completed_on"], :name => "index_project_tasks_on_completed_on"
    add_index "project_tasks", ["created_on"], :name => "index_project_tasks_on_created_on"
    add_index "project_tasks", ["order"], :name => "index_project_tasks_on_order"
  
    create_table "project_times", :force => true do |t|
      t.integer  "project_id"
      t.integer  "task_list_id"
      t.integer  "task_id"
      t.string   "name",                   :limit => 100
      t.text     "description"
      t.datetime "done_date"
      t.float    "hours",                                 :default => 0.0,   :null => false
      t.boolean  "is_billable",                           :default => true,  :null => false
      t.integer  "assigned_to_company_id",                :default => 0,     :null => false
      t.integer  "assigned_to_user_id",                   :default => 0,     :null => false
      t.boolean  "is_private",                            :default => false, :null => false
      t.datetime "created_on",                                               :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
    end
  
    add_index "project_times", ["project_id"], :name => "index_project_times_on_project_id"
    add_index "project_times", ["done_date"], :name => "index_project_times_on_done_date"
    add_index "project_times", ["created_on"], :name => "index_project_times_on_created_on"
  
    create_table "project_users", :id => false, :force => true do |t|
      t.integer  "project_id",            :default => 0,     :null => false
      t.integer  "user_id",               :default => 0,     :null => false
      t.datetime "created_on"
      t.integer  "created_by_id",         :default => 0,     :null => false
      t.boolean  "can_manage_messages",   :default => false
      t.boolean  "can_manage_tasks",      :default => false
      t.boolean  "can_manage_milestones", :default => false
      t.boolean  "can_upload_files",      :default => false
      t.boolean  "can_manage_files",      :default => false
      t.boolean  "can_assign_to_owners",  :default => false, :null => false
      t.boolean  "can_assign_to_other",   :default => false, :null => false
      t.boolean  "can_manage_time",       :default => false, :null => false
    end
  
    create_table "projects", :force => true do |t|
      t.integer  "priority"
      t.string   "name",                         :limit => 50
      t.text     "description"
      t.boolean  "show_description_in_overview",               :default => false, :null => false
      t.datetime "completed_on"
      t.integer  "completed_by_id"
      t.datetime "created_on",                                                    :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.integer  "updated_by_id"
    end
  
    add_index "projects", ["completed_on"], :name => "index_projects_on_completed_on"
  
    create_table "searchable_objects", :id => false, :force => true do |t|
      t.string  "rel_object_type", :limit => 50, :default => "",    :null => false
      t.integer "rel_object_id",                 :default => 0,     :null => false
      t.string  "column_name",     :limit => 50, :default => "",    :null => false
      t.text    "content",                                          :null => false
      t.integer "project_id",                    :default => 0,     :null => false
      t.boolean "is_private",                    :default => false, :null => false
    end
  
    add_index "searchable_objects", ["project_id"], :name => "index_searchable_objects_on_project_id"
    add_index "searchable_objects", ["rel_object_id", "rel_object_type"], :name => "index_searchable_objects_on_rel_object_id_and_rel_object_type"
  
    create_table "tags", :force => true do |t|
      t.integer  "project_id",                    :default => 0,     :null => false
      t.string   "tag",             :limit => 30, :default => "",    :null => false
      t.integer  "rel_object_id",                 :default => 0,     :null => false
      t.string   "rel_object_type", :limit => 50, :default => "",    :null => false
      t.datetime "created_on"
      t.integer  "created_by_id",                 :default => 0,     :null => false
      t.boolean  "is_private",                    :default => false, :null => false
    end
  
    add_index "tags", ["project_id"], :name => "index_tags_on_project_id"
    add_index "tags", ["tag"], :name => "index_tags_on_tag"
    add_index "tags", ["rel_object_id", "rel_object_type"], :name => "index_tags_on_rel_object_id_and_rel_object_type"
  
    create_table "user_im_values", :id => false, :force => true do |t|
      t.integer "user_id",                  :default => 0,     :null => false
      t.integer "im_type_id", :limit => 3,  :default => 0,     :null => false
      t.string  "value",      :limit => 50, :default => "",    :null => false
      t.boolean "is_default",               :default => false, :null => false
    end
  
    add_index "user_im_values", ["is_default"], :name => "index_user_im_values_on_is_default"
  
    create_table "users", :force => true do |t|
      t.integer  "company_id",        :limit => 8,   :default => 0,     :null => false
      t.string   "username",          :limit => 50,  :default => "",    :null => false
      t.string   "email",             :limit => 100
      t.string   "token",             :limit => 40,  :default => "",    :null => false
      t.string   "salt",              :limit => 13,  :default => "",    :null => false
      t.string   "twister",           :limit => 10,  :default => "",    :null => false
      t.string   "display_name",      :limit => 50
      t.string   "title",             :limit => 30
      t.string   "avatar_file",       :limit => 44
      t.string   "office_number",     :limit => 20
      t.string   "fax_number",        :limit => 20
      t.string   "mobile_number",     :limit => 20
      t.string   "home_number",       :limit => 20
      t.float    "timezone",                         :default => 0.0,   :null => false
      t.datetime "created_on",                                          :null => false
      t.integer  "created_by_id"
      t.datetime "updated_on"
      t.datetime "last_login"
      t.datetime "last_visit"
      t.datetime "last_activity"
      t.boolean  "is_admin"
      t.boolean  "auto_assign",                      :default => false, :null => false
      t.string   "identity_url"
      t.string   "office_number_ext", :limit => 5
    end
  
    add_index "users", ["username"], :name => "index_users_on_username", :unique => true
    add_index "users", ["email"], :name => "index_users_on_email", :unique => true
    add_index "users", ["last_visit"], :name => "index_users_on_last_visit"
    add_index "users", ["company_id"], :name => "index_users_on_company_id"
    add_index "users", ["last_login"], :name => "index_users_on_last_login"
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
  	drop_table :project_message_categories
  	drop_table :project_milestones
  	drop_table :project_task_lists
  	drop_table :project_tasks
  	drop_table :project_times
  	drop_table :project_users
  	drop_table :projects
  	drop_table :searchable_objects
  	drop_table :tags
  	drop_table :user_im_values
  	drop_table :users
    
    # OpenID
    drop_table :open_id_associations
    drop_table :open_id_nonces
    drop_table :open_id_settings
  end
end
