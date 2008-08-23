# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 12) do

  create_table "administration_tools", :force => true do |t|
    t.string  "name",       :limit => 50, :default => "", :null => false
    t.string  "controller", :limit => 50, :default => "", :null => false
    t.string  "action",     :limit => 50, :default => "", :null => false
    t.integer "order",      :limit => 3,  :default => 0,  :null => false
  end

  add_index "administration_tools", ["name"], :name => "index_administration_tools_on_name", :unique => true

  create_table "application_logs", :force => true do |t|
    t.integer  "taken_by_id",     :limit => 10
    t.integer  "project_id",      :limit => 10, :default => 0,     :null => false
    t.integer  "rel_object_id",   :limit => 10, :default => 0,     :null => false
    t.text     "object_name"
    t.string   "rel_object_type", :limit => 50
    t.datetime "created_on",                                       :null => false
    t.integer  "created_by_id",   :limit => 10
    t.boolean  "is_private",                    :default => false, :null => false
    t.boolean  "is_silent",                     :default => false, :null => false
    t.integer  "action_id",       :limit => 1
  end

  add_index "application_logs", ["created_on"], :name => "index_application_logs_on_created_on"
  add_index "application_logs", ["project_id"], :name => "index_application_logs_on_project_id"

  create_table "attached_files", :id => false, :force => true do |t|
    t.string   "rel_object_type", :limit => 50
    t.integer  "rel_object_id",   :limit => 10, :default => 0, :null => false
    t.integer  "file_id",         :limit => 10, :default => 0, :null => false
    t.datetime "created_on",                                   :null => false
    t.integer  "created_by_id",   :limit => 10
  end

  create_table "comments", :force => true do |t|
    t.integer  "rel_object_id",        :limit => 10,  :default => 0,     :null => false
    t.string   "rel_object_type",      :limit => 30
    t.text     "text"
    t.boolean  "is_private",                          :default => false, :null => false
    t.boolean  "is_anonymous",                        :default => false, :null => false
    t.string   "author_name",          :limit => 50
    t.string   "author_email",         :limit => 100
    t.string   "author_homepage",      :limit => 100, :default => "",    :null => false
    t.datetime "created_on",                                             :null => false
    t.integer  "created_by_id",        :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",        :limit => 10
    t.integer  "attached_files_count", :limit => 11,  :default => 0
  end

  add_index "comments", ["created_on"], :name => "index_comments_on_created_on"
  add_index "comments", ["rel_object_id", "rel_object_type"], :name => "index_comments_on_rel_object_id_and_rel_object_type"

  create_table "companies", :force => true do |t|
    t.integer  "client_of_id",      :limit => 5
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
    t.boolean  "hide_welcome_info",                :default => false, :null => false
    t.datetime "created_on",                                          :null => false
    t.integer  "created_by_id",     :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",     :limit => 10
    t.string   "time_zone",                        :default => "",    :null => false
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
    t.integer "option_order",         :limit => 5,  :default => 0,     :null => false
    t.string  "dev_comment"
  end

  add_index "config_options", ["name"], :name => "index_config_options_on_name", :unique => true
  add_index "config_options", ["option_order"], :name => "index_config_options_on_option_order"
  add_index "config_options", ["category_name"], :name => "index_config_options_on_category_name"

  create_table "file_repo", :force => true do |t|
    t.binary  "content",                                 :null => false
    t.integer "order",      :limit => 10, :default => 0, :null => false
    t.integer "storage_id", :limit => 1,  :default => 0, :null => false
  end

  add_index "file_repo", ["order"], :name => "index_file_repo_on_order"

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
    t.integer "message_id", :limit => 10, :default => 0, :null => false
    t.integer "user_id",    :limit => 10, :default => 0, :null => false
  end

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued",     :limit => 11
    t.integer "lifetime",   :limit => 11
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :limit => 11,                 :null => false
    t.string  "server_url"
    t.string  "salt",                     :default => "", :null => false
  end

  create_table "project_companies", :id => false, :force => true do |t|
    t.integer "project_id",       :limit => 10, :default => 0,     :null => false
    t.integer "company_id",       :limit => 5,  :default => 0,     :null => false
    t.boolean "can_view_private",               :default => false, :null => false
  end

  create_table "project_file_revisions", :force => true do |t|
    t.integer  "file_id",         :limit => 10, :default => 0,  :null => false
    t.integer  "file_type_id",    :limit => 5,  :default => 0,  :null => false
    t.string   "repository_id",   :limit => 40, :default => "", :null => false
    t.string   "thumb_filename",  :limit => 44
    t.integer  "revision_number", :limit => 10, :default => 0,  :null => false
    t.text     "comment"
    t.string   "type_string",     :limit => 50, :default => "", :null => false
    t.integer  "filesize",        :limit => 10, :default => 0,  :null => false
    t.datetime "created_on",                                    :null => false
    t.integer  "created_by_id",   :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",   :limit => 10
  end

  add_index "project_file_revisions", ["file_id"], :name => "index_project_file_revisions_on_file_id"
  add_index "project_file_revisions", ["updated_on"], :name => "index_project_file_revisions_on_updated_on"
  add_index "project_file_revisions", ["revision_number"], :name => "index_project_file_revisions_on_revision_number"

  create_table "project_files", :force => true do |t|
    t.integer  "project_id",                 :limit => 10,  :default => 0,     :null => false
    t.integer  "folder_id",                  :limit => 5,   :default => 0,     :null => false
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
    t.integer  "created_by_id",              :limit => 10,  :default => 0
    t.datetime "updated_on"
    t.integer  "updated_by_id",              :limit => 10,  :default => 0
    t.integer  "comments_count",             :limit => 11,  :default => 0
    t.boolean  "can_time_track",                            :default => false, :null => false
  end

  add_index "project_files", ["project_id"], :name => "index_project_files_on_project_id"

  create_table "project_folders", :force => true do |t|
    t.integer "project_id",          :limit => 10, :default => 0,  :null => false
    t.string  "name",                :limit => 50, :default => "", :null => false
    t.integer "project_files_count", :limit => 11, :default => 0
  end

  add_index "project_folders", ["project_id", "name"], :name => "index_project_folders_on_project_id_and_name", :unique => true

  create_table "project_forms", :force => true do |t|
    t.integer  "project_id",      :limit => 10, :default => 0,     :null => false
    t.string   "name",            :limit => 50, :default => "",    :null => false
    t.text     "description",                                      :null => false
    t.text     "success_message",                                  :null => false
    t.integer  "in_object_id",    :limit => 10, :default => 0,     :null => false
    t.datetime "created_on"
    t.integer  "created_by_id",   :limit => 10, :default => 0,     :null => false
    t.datetime "updated_on"
    t.integer  "updated_by_id",   :limit => 10, :default => 0,     :null => false
    t.boolean  "is_visible",                    :default => false, :null => false
    t.boolean  "is_enabled",                    :default => false, :null => false
    t.integer  "order",           :limit => 6,  :default => 0,     :null => false
    t.integer  "action_id",       :limit => 1
  end

  create_table "project_message_categories", :force => true do |t|
    t.integer "project_id",             :limit => 10,                 :null => false
    t.string  "name",                   :limit => 50, :default => "", :null => false
    t.integer "project_messages_count", :limit => 11, :default => 0
  end

  create_table "project_messages", :force => true do |t|
    t.integer  "milestone_id",               :limit => 10,  :default => 0,     :null => false
    t.integer  "project_id",                 :limit => 10
    t.string   "title",                      :limit => 100
    t.text     "text"
    t.text     "additional_text"
    t.boolean  "is_important",                              :default => false, :null => false
    t.boolean  "is_private",                                :default => false, :null => false
    t.boolean  "comments_enabled",                          :default => false, :null => false
    t.boolean  "anonymous_comments_enabled",                :default => false, :null => false
    t.datetime "created_on",                                                   :null => false
    t.integer  "created_by_id",              :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",              :limit => 10
    t.integer  "category_id",                :limit => 5,                      :null => false
    t.integer  "comments_count",             :limit => 11,  :default => 0
    t.integer  "attached_files_count",       :limit => 11,  :default => 0
  end

  add_index "project_messages", ["milestone_id"], :name => "index_project_messages_on_milestone_id"
  add_index "project_messages", ["project_id"], :name => "index_project_messages_on_project_id"
  add_index "project_messages", ["created_on"], :name => "index_project_messages_on_created_on"

  create_table "project_milestones", :force => true do |t|
    t.integer  "project_id",             :limit => 10
    t.string   "name",                   :limit => 100
    t.text     "description"
    t.datetime "due_date"
    t.integer  "assigned_to_company_id", :limit => 10,  :default => 0,     :null => false
    t.integer  "assigned_to_user_id",    :limit => 10,  :default => 0,     :null => false
    t.boolean  "is_private",                            :default => false, :null => false
    t.datetime "completed_on"
    t.integer  "completed_by_id",        :limit => 10
    t.datetime "created_on",                                               :null => false
    t.integer  "created_by_id",          :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",          :limit => 10
  end

  add_index "project_milestones", ["project_id"], :name => "index_project_milestones_on_project_id"
  add_index "project_milestones", ["due_date"], :name => "index_project_milestones_on_due_date"
  add_index "project_milestones", ["completed_on"], :name => "index_project_milestones_on_completed_on"
  add_index "project_milestones", ["created_on"], :name => "index_project_milestones_on_created_on"

  create_table "project_task_lists", :force => true do |t|
    t.integer  "priority",        :limit => 11
    t.integer  "milestone_id",    :limit => 10,  :default => 0,     :null => false
    t.integer  "project_id",      :limit => 10
    t.string   "name",            :limit => 100
    t.text     "description"
    t.boolean  "is_private",                     :default => false, :null => false
    t.datetime "completed_on"
    t.integer  "completed_by_id", :limit => 10
    t.datetime "created_on"
    t.integer  "created_by_id",   :limit => 10,  :default => 0,     :null => false
    t.datetime "updated_on"
    t.integer  "updated_by_id",   :limit => 10,  :default => 0,     :null => false
    t.integer  "order",           :limit => 3,   :default => 0,     :null => false
  end

  add_index "project_task_lists", ["milestone_id"], :name => "index_project_task_lists_on_milestone_id"
  add_index "project_task_lists", ["project_id"], :name => "index_project_task_lists_on_project_id"
  add_index "project_task_lists", ["completed_on"], :name => "index_project_task_lists_on_completed_on"
  add_index "project_task_lists", ["created_on"], :name => "index_project_task_lists_on_created_on"

  create_table "project_tasks", :force => true do |t|
    t.integer  "task_list_id",           :limit => 10
    t.text     "text"
    t.integer  "assigned_to_company_id", :limit => 5
    t.integer  "assigned_to_user_id",    :limit => 10
    t.datetime "completed_on"
    t.integer  "completed_by_id",        :limit => 10
    t.datetime "created_on",                                          :null => false
    t.integer  "created_by_id",          :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",          :limit => 10
    t.integer  "order",                  :limit => 10, :default => 0, :null => false
  end

  add_index "project_tasks", ["task_list_id"], :name => "index_project_tasks_on_task_list_id"
  add_index "project_tasks", ["completed_on"], :name => "index_project_tasks_on_completed_on"
  add_index "project_tasks", ["created_on"], :name => "index_project_tasks_on_created_on"
  add_index "project_tasks", ["order"], :name => "index_project_tasks_on_order"

  create_table "project_times", :force => true do |t|
    t.integer  "project_id",             :limit => 10
    t.integer  "task_list_id",           :limit => 11
    t.integer  "task_id",                :limit => 11
    t.string   "name",                   :limit => 100
    t.text     "description"
    t.datetime "done_date"
    t.float    "hours",                                 :default => 0.0,   :null => false
    t.boolean  "is_billable",                           :default => true,  :null => false
    t.integer  "assigned_to_company_id", :limit => 10,  :default => 0,     :null => false
    t.integer  "assigned_to_user_id",    :limit => 10,  :default => 0,     :null => false
    t.boolean  "is_private",                            :default => false, :null => false
    t.datetime "created_on",                                               :null => false
    t.integer  "created_by_id",          :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",          :limit => 10
  end

  add_index "project_times", ["project_id"], :name => "index_project_times_on_project_id"
  add_index "project_times", ["done_date"], :name => "index_project_times_on_done_date"
  add_index "project_times", ["created_on"], :name => "index_project_times_on_created_on"

  create_table "project_users", :id => false, :force => true do |t|
    t.integer  "project_id",            :limit => 10, :default => 0,     :null => false
    t.integer  "user_id",               :limit => 10, :default => 0,     :null => false
    t.datetime "created_on"
    t.integer  "created_by_id",         :limit => 10, :default => 0,     :null => false
    t.boolean  "can_manage_messages",                 :default => false
    t.boolean  "can_manage_tasks",                    :default => false
    t.boolean  "can_manage_milestones",               :default => false
    t.boolean  "can_upload_files",                    :default => false
    t.boolean  "can_manage_files",                    :default => false
    t.boolean  "can_assign_to_owners",                :default => false, :null => false
    t.boolean  "can_assign_to_other",                 :default => false, :null => false
    t.boolean  "can_manage_time",                     :default => false, :null => false
  end

  create_table "projects", :force => true do |t|
    t.integer  "priority",                     :limit => 11
    t.string   "name",                         :limit => 50
    t.text     "description"
    t.boolean  "show_description_in_overview",               :default => false, :null => false
    t.datetime "completed_on"
    t.integer  "completed_by_id",              :limit => 11
    t.datetime "created_on",                                                    :null => false
    t.integer  "created_by_id",                :limit => 10
    t.datetime "updated_on"
    t.integer  "updated_by_id",                :limit => 10
  end

  add_index "projects", ["completed_on"], :name => "index_projects_on_completed_on"

  create_table "tags", :force => true do |t|
    t.integer  "project_id",      :limit => 10, :default => 0,     :null => false
    t.string   "tag",             :limit => 30, :default => "",    :null => false
    t.integer  "rel_object_id",   :limit => 10, :default => 0,     :null => false
    t.string   "rel_object_type", :limit => 50
    t.datetime "created_on"
    t.integer  "created_by_id",   :limit => 10, :default => 0,     :null => false
    t.boolean  "is_private",                    :default => false, :null => false
  end

  add_index "tags", ["project_id"], :name => "index_tags_on_project_id"
  add_index "tags", ["tag"], :name => "index_tags_on_tag"
  add_index "tags", ["rel_object_id", "rel_object_type"], :name => "index_tags_on_rel_object_id_and_rel_object_type"

  create_table "user_im_values", :id => false, :force => true do |t|
    t.integer "user_id",    :limit => 10, :default => 0,     :null => false
    t.integer "im_type_id", :limit => 3,  :default => 0,     :null => false
    t.string  "value",      :limit => 50, :default => "",    :null => false
    t.boolean "is_default",               :default => false, :null => false
  end

  add_index "user_im_values", ["is_default"], :name => "index_user_im_values_on_is_default"

  create_table "users", :force => true do |t|
    t.integer  "company_id",        :limit => 5,   :default => 0,     :null => false
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
    t.datetime "created_on",                                          :null => false
    t.integer  "created_by_id",     :limit => 10
    t.datetime "updated_on"
    t.datetime "last_login"
    t.datetime "last_visit"
    t.datetime "last_activity"
    t.boolean  "is_admin",                         :default => false, :null => false
    t.boolean  "auto_assign",                      :default => false, :null => false
    t.string   "identity_url"
    t.string   "office_number_ext", :limit => 5
    t.string   "time_zone",                        :default => "",    :null => false
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["last_visit"], :name => "index_users_on_last_visit"
  add_index "users", ["company_id"], :name => "index_users_on_company_id"
  add_index "users", ["last_login"], :name => "index_users_on_last_login"

end
