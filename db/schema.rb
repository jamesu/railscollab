# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111005191500) do

  create_table "activities", :force => true do |t|
    t.integer  "project_id",                    :default => 0,     :null => false
    t.integer  "rel_object_id",                 :default => 0
    t.text     "object_name"
    t.string   "rel_object_type", :limit => 50, :default => "",    :null => false
    t.datetime "created_on",                                       :null => false
    t.integer  "created_by_id"
    t.boolean  "is_private",                    :default => false, :null => false
    t.boolean  "is_silent",                     :default => false, :null => false
    t.integer  "action_id",       :limit => 1
  end

  add_index "activities", ["created_on"], :name => "index_application_logs_on_created_on"
  add_index "activities", ["project_id"], :name => "index_application_logs_on_project_id"

  create_table "attached_files", :id => false, :force => true do |t|
    t.string   "rel_object_type", :limit => 50, :default => "", :null => false
    t.integer  "rel_object_id",                 :default => 0,  :null => false
    t.integer  "file_id",                       :default => 0,  :null => false
    t.datetime "created_on",                                    :null => false
    t.integer  "created_by_id"
  end

  create_table "categories", :force => true do |t|
    t.integer "project_id",                                   :null => false
    t.string  "name",           :limit => 50, :default => "", :null => false
    t.integer "messages_count",               :default => 0
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
    t.integer  "project_id"
  end

  add_index "comments", ["created_on"], :name => "index_comments_on_created_on"
  add_index "comments", ["project_id"], :name => "index_comments_on_project_id"
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
    t.string   "country",           :limit => 100
    t.string   "phone_number",      :limit => 30
    t.string   "fax_number",        :limit => 30
    t.boolean  "hide_welcome_info",                :default => false, :null => false
    t.datetime "created_on",                                          :null => false
    t.integer  "created_by_id"
    t.datetime "updated_on"
    t.integer  "updated_by_id"
    t.string   "time_zone",                        :default => "",    :null => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
  end

  add_index "companies", ["client_of_id"], :name => "index_companies_on_client_of_id"
  add_index "companies", ["created_on"], :name => "index_companies_on_created_on"

  create_table "file_types", :force => true do |t|
    t.string  "extension",     :limit => 10, :default => "",    :null => false
    t.string  "icon",          :limit => 30, :default => "",    :null => false
    t.boolean "is_searchable",               :default => false, :null => false
    t.boolean "is_image",                    :default => false, :null => false
  end

  add_index "file_types", ["extension"], :name => "index_file_types_on_extension", :unique => true

  create_table "folders", :force => true do |t|
    t.integer "project_id",                        :default => 0,  :null => false
    t.string  "name",                :limit => 50, :default => "", :null => false
    t.integer "project_files_count",               :default => 0
  end

  add_index "folders", ["project_id", "name"], :name => "index_project_folders_on_project_id_and_name", :unique => true

  create_table "im_types", :force => true do |t|
    t.string "name", :limit => 30, :default => "", :null => false
    t.string "icon", :limit => 30, :default => "", :null => false
  end

  create_table "message_subscriptions", :id => false, :force => true do |t|
    t.integer "message_id", :default => 0, :null => false
    t.integer "user_id",    :default => 0, :null => false
  end

  create_table "messages", :force => true do |t|
    t.integer  "milestone_id"
    t.integer  "project_id"
    t.string   "title",                      :limit => 100
    t.text     "text"
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

  add_index "messages", ["created_on"], :name => "index_project_messages_on_created_on"
  add_index "messages", ["milestone_id"], :name => "index_project_messages_on_milestone_id"
  add_index "messages", ["project_id"], :name => "index_project_messages_on_project_id"

  create_table "milestones", :force => true do |t|
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

  add_index "milestones", ["completed_on"], :name => "index_project_milestones_on_completed_on"
  add_index "milestones", ["created_on"], :name => "index_project_milestones_on_created_on"
  add_index "milestones", ["due_date"], :name => "index_project_milestones_on_due_date"
  add_index "milestones", ["project_id"], :name => "index_project_milestones_on_project_id"

  create_table "people", :force => true do |t|
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
    t.boolean  "can_manage_wiki_pages", :default => false, :null => false
  end

  create_table "project_companies", :id => false, :force => true do |t|
    t.integer "project_id",                    :default => 0,     :null => false
    t.integer "company_id",       :limit => 8, :default => 0,     :null => false
    t.boolean "can_view_private",              :default => false, :null => false
  end

  create_table "project_file_revisions", :force => true do |t|
    t.integer  "file_id",                         :default => 0,     :null => false
    t.integer  "file_type_id",      :limit => 8,  :default => 0,     :null => false
    t.integer  "revision_number",                 :default => 0,     :null => false
    t.text     "comment"
    t.string   "type_string",       :limit => 50, :default => "",    :null => false
    t.integer  "filesize",                        :default => 0,     :null => false
    t.datetime "created_on",                                         :null => false
    t.integer  "created_by_id"
    t.datetime "updated_on"
    t.integer  "updated_by_id"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.datetime "data_updated_at"
    t.boolean  "has_thumbnail",                   :default => false
    t.integer  "project_id"
  end

  add_index "project_file_revisions", ["file_id"], :name => "index_project_file_revisions_on_file_id"
  add_index "project_file_revisions", ["project_id"], :name => "index_project_file_revisions_on_project_id"
  add_index "project_file_revisions", ["revision_number"], :name => "index_project_file_revisions_on_revision_number"
  add_index "project_file_revisions", ["updated_on"], :name => "index_project_file_revisions_on_updated_on"

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

  create_table "slugs", :force => true do |t|
    t.string   "name"
    t.integer  "sluggable_id"
    t.integer  "sequence",                     :default => 1, :null => false
    t.string   "sluggable_type", :limit => 40
    t.string   "scope",          :limit => 40
    t.datetime "created_at"
  end

  add_index "slugs", ["name", "sluggable_type", "scope", "sequence"], :name => "index_slugs_on_name_and_sluggable_type_and_scope_and_sequence", :unique => true
  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"

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
  add_index "tags", ["rel_object_id", "rel_object_type"], :name => "index_tags_on_rel_object_id_and_rel_object_type"
  add_index "tags", ["tag"], :name => "index_tags_on_tag"

  create_table "task_lists", :force => true do |t|
    t.integer  "priority"
    t.integer  "milestone_id"
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

  add_index "task_lists", ["completed_on"], :name => "index_project_task_lists_on_completed_on"
  add_index "task_lists", ["created_on"], :name => "index_project_task_lists_on_created_on"
  add_index "task_lists", ["milestone_id"], :name => "index_project_task_lists_on_milestone_id"
  add_index "task_lists", ["project_id"], :name => "index_project_task_lists_on_project_id"

  create_table "tasks", :force => true do |t|
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
    t.integer  "comments_count",                      :default => 0
    t.float    "estimated_hours"
    t.integer  "project_id"
  end

  add_index "tasks", ["completed_on"], :name => "index_project_tasks_on_completed_on"
  add_index "tasks", ["created_on"], :name => "index_project_tasks_on_created_on"
  add_index "tasks", ["order"], :name => "index_project_tasks_on_order"
  add_index "tasks", ["project_id"], :name => "index_tasks_on_project_id"
  add_index "tasks", ["task_list_id"], :name => "index_project_tasks_on_task_list_id"

  create_table "time_records", :force => true do |t|
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
    t.datetime "start_date"
  end

  add_index "time_records", ["created_on"], :name => "index_project_times_on_created_on"
  add_index "time_records", ["done_date"], :name => "index_project_times_on_done_date"
  add_index "time_records", ["project_id"], :name => "index_project_times_on_project_id"

  create_table "user_im_values", :force => true do |t|
    t.integer "user_id",                  :default => 0,     :null => false
    t.integer "im_type_id", :limit => 3,  :default => 0,     :null => false
    t.string  "value",      :limit => 50, :default => "",    :null => false
    t.boolean "is_default",               :default => false, :null => false
  end

  add_index "user_im_values", ["is_default"], :name => "index_user_im_values_on_is_default"

  create_table "users", :force => true do |t|
    t.integer  "company_id",                :limit => 8,   :default => 0,     :null => false
    t.string   "username",                  :limit => 50,  :default => "",    :null => false
    t.string   "email",                     :limit => 100
    t.string   "token",                     :limit => 40,  :default => "",    :null => false
    t.string   "salt",                      :limit => 13,  :default => "",    :null => false
    t.string   "twister",                   :limit => 10,  :default => "",    :null => false
    t.string   "display_name",              :limit => 50
    t.string   "title"
    t.string   "office_number",             :limit => 20
    t.string   "fax_number",                :limit => 20
    t.string   "mobile_number",             :limit => 20
    t.string   "home_number",               :limit => 20
    t.datetime "created_on",                                                  :null => false
    t.integer  "created_by_id"
    t.datetime "updated_on"
    t.datetime "last_login"
    t.datetime "last_visit"
    t.datetime "last_activity"
    t.boolean  "is_admin",                                 :default => false, :null => false
    t.boolean  "auto_assign",                              :default => false, :null => false
    t.string   "office_number_ext",         :limit => 5
    t.string   "time_zone",                                :default => "",    :null => false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
  end

  add_index "users", ["company_id"], :name => "index_users_on_company_id"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["last_login"], :name => "index_users_on_last_login"
  add_index "users", ["last_visit"], :name => "index_users_on_last_visit"
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "wiki_page_versions", :force => true do |t|
    t.integer  "wiki_page_id"
    t.integer  "version"
    t.string   "title"
    t.text     "content"
    t.boolean  "main",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.integer  "created_by_id"
  end

  add_index "wiki_page_versions", ["wiki_page_id"], :name => "index_wiki_page_versions_on_wiki_page_id"

  create_table "wiki_pages", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.boolean  "main",          :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version"
    t.integer  "project_id"
    t.integer  "created_by_id"
    t.string   "slug"
  end

  add_index "wiki_pages", ["main"], :name => "index_wiki_pages_on_main"
  add_index "wiki_pages", ["project_id"], :name => "index_wiki_pages_on_project_id"
  add_index "wiki_pages", ["slug"], :name => "index_wiki_pages_on_slug"

end
