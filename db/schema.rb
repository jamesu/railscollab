# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2023_10_05_220129) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.integer "project_id", default: 0, null: false
    t.integer "rel_object_id", default: 0
    t.text "object_name"
    t.string "rel_object_type", limit: 50, default: "", null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.boolean "is_private", default: false, null: false
    t.boolean "is_silent", default: false, null: false
    t.integer "action_id", limit: 1
    t.index ["created_on"], name: "index_activities_on_created_on"
    t.index ["project_id"], name: "index_activities_on_project_id"
  end

  create_table "attached_files", id: false, force: :cascade do |t|
    t.string "rel_object_type", limit: 50, default: "", null: false
    t.integer "rel_object_id", default: 0, null: false
    t.integer "file_id", default: 0, null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
  end

  create_table "categories", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", limit: 50, default: "", null: false
    t.integer "messages_count", default: 0
  end

  create_table "comments", force: :cascade do |t|
    t.integer "rel_object_id", default: 0, null: false
    t.string "rel_object_type", limit: 30, default: "", null: false
    t.text "text"
    t.boolean "is_private", default: false, null: false
    t.boolean "is_anonymous", default: false, null: false
    t.string "author_name", limit: 50
    t.string "author_email", limit: 100
    t.string "author_homepage", limit: 100, default: "", null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.integer "attached_files_count", default: 0
    t.integer "project_id"
    t.index ["created_on"], name: "index_comments_on_created_on"
    t.index ["project_id"], name: "index_comments_on_project_id"
    t.index ["rel_object_id", "rel_object_type"], name: "index_comments_on_rel_object_id_and_rel_object_type"
  end

  create_table "companies", force: :cascade do |t|
    t.integer "client_of_id", limit: 8
    t.string "name", limit: 50
    t.string "email", limit: 100
    t.string "homepage", limit: 100
    t.string "address", limit: 100
    t.string "address2", limit: 100
    t.string "city", limit: 50
    t.string "state", limit: 50
    t.string "zipcode", limit: 30
    t.string "country", limit: 100
    t.string "phone_number", limit: 30
    t.string "fax_number", limit: 30
    t.boolean "hide_welcome_info", default: false, null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.string "time_zone", default: "", null: false
    t.string "logo_file_name"
    t.string "logo_content_type"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at", precision: nil
    t.index ["client_of_id"], name: "index_companies_on_client_of_id"
    t.index ["created_on"], name: "index_companies_on_created_on"
  end

  create_table "file_types", force: :cascade do |t|
    t.string "extension", limit: 10, default: "", null: false
    t.string "icon", limit: 30, default: "", null: false
    t.boolean "is_searchable", default: false, null: false
    t.boolean "is_image", default: false, null: false
    t.index ["extension"], name: "index_file_types_on_extension", unique: true
  end

  create_table "folders", force: :cascade do |t|
    t.integer "project_id", default: 0, null: false
    t.string "name", limit: 50, default: "", null: false
    t.integer "project_files_count", default: 0
    t.index ["project_id", "name"], name: "index_folders_on_project_id_and_name", unique: true
  end

  create_table "im_types", force: :cascade do |t|
    t.string "name", limit: 30, default: "", null: false
    t.string "icon", limit: 30, default: "", null: false
  end

  create_table "message_subscriptions", id: false, force: :cascade do |t|
    t.integer "message_id", default: 0, null: false
    t.integer "user_id", default: 0, null: false
  end

  create_table "messages", force: :cascade do |t|
    t.integer "milestone_id"
    t.integer "project_id"
    t.string "title", limit: 100
    t.text "text"
    t.boolean "is_important", default: false, null: false
    t.boolean "is_private", default: false, null: false
    t.boolean "comments_enabled", default: false, null: false
    t.boolean "anonymous_comments_enabled", default: false, null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.integer "category_id", limit: 8, null: false
    t.integer "comments_count", default: 0
    t.integer "attached_files_count", default: 0
    t.index ["created_on"], name: "index_messages_on_created_on"
    t.index ["milestone_id"], name: "index_messages_on_milestone_id"
    t.index ["project_id"], name: "index_messages_on_project_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.integer "project_id"
    t.string "name", limit: 100
    t.text "description"
    t.datetime "due_date", precision: nil
    t.integer "assigned_to_company_id", default: 0, null: false
    t.integer "assigned_to_user_id", default: 0, null: false
    t.boolean "is_private", default: false, null: false
    t.datetime "completed_on", precision: nil
    t.integer "completed_by_id"
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.index ["completed_on"], name: "index_milestones_on_completed_on"
    t.index ["created_on"], name: "index_milestones_on_created_on"
    t.index ["due_date"], name: "index_milestones_on_due_date"
    t.index ["project_id"], name: "index_milestones_on_project_id"
  end

  create_table "people", force: :cascade do |t|
    t.integer "project_id", default: 0, null: false
    t.integer "user_id", default: 0, null: false
    t.datetime "created_on", precision: nil
    t.integer "created_by_id", default: 0, null: false
    t.boolean "can_manage_messages", default: false
    t.boolean "can_manage_tasks", default: false
    t.boolean "can_manage_milestones", default: false
    t.boolean "can_upload_files", default: false
    t.boolean "can_manage_files", default: false
    t.boolean "can_assign_to_owners", default: false, null: false
    t.boolean "can_assign_to_other", default: false, null: false
    t.boolean "can_manage_time", default: false, null: false
    t.boolean "can_manage_wiki_pages", default: false, null: false
  end

  create_table "project_companies", id: false, force: :cascade do |t|
    t.integer "project_id", default: 0, null: false
    t.integer "company_id", limit: 8, default: 0, null: false
    t.boolean "can_view_private", default: false, null: false
  end

  create_table "project_file_revisions", force: :cascade do |t|
    t.integer "file_id", default: 0, null: false
    t.integer "file_type_id", limit: 8, default: 0, null: false
    t.integer "revision_number", default: 0, null: false
    t.text "comment"
    t.string "type_string", limit: 50, default: "", null: false
    t.integer "filesize", default: 0, null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.string "data_file_name"
    t.string "data_content_type"
    t.integer "data_file_size"
    t.datetime "data_updated_at", precision: nil
    t.boolean "has_thumbnail", default: false
    t.integer "project_id"
    t.index ["file_id"], name: "index_project_file_revisions_on_file_id"
    t.index ["project_id"], name: "index_project_file_revisions_on_project_id"
    t.index ["revision_number"], name: "index_project_file_revisions_on_revision_number"
    t.index ["updated_on"], name: "index_project_file_revisions_on_updated_on"
  end

  create_table "project_files", force: :cascade do |t|
    t.integer "project_id", default: 0, null: false
    t.integer "folder_id", limit: 8, default: 0, null: false
    t.string "filename", limit: 100, default: "", null: false
    t.text "description"
    t.boolean "is_private", default: false, null: false
    t.boolean "is_important", default: false, null: false
    t.boolean "is_locked", default: false, null: false
    t.boolean "is_visible", default: false, null: false
    t.datetime "expiration_time", precision: nil
    t.boolean "comments_enabled", default: false, null: false
    t.boolean "anonymous_comments_enabled", default: false, null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id", default: 0
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id", default: 0
    t.integer "comments_count", default: 0
    t.boolean "can_time_track", default: false, null: false
    t.index ["project_id"], name: "index_project_files_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "priority"
    t.string "name", limit: 50
    t.text "description"
    t.boolean "show_description_in_overview", default: false, null: false
    t.datetime "completed_on", precision: nil
    t.integer "completed_by_id"
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.index ["completed_on"], name: "index_projects_on_completed_on"
  end

  create_table "slugs", force: :cascade do |t|
    t.string "name"
    t.integer "sluggable_id"
    t.integer "sequence", default: 1, null: false
    t.string "sluggable_type", limit: 40
    t.string "scope", limit: 40
    t.datetime "created_at", precision: nil
    t.index ["name", "sluggable_type", "scope", "sequence"], name: "index_slugs_on_name_and_sluggable_type_and_scope_and_sequence", unique: true
    t.index ["sluggable_id"], name: "index_slugs_on_sluggable_id"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "project_id", default: 0, null: false
    t.string "tag", limit: 30, default: "", null: false
    t.integer "rel_object_id", default: 0, null: false
    t.string "rel_object_type", limit: 50, default: "", null: false
    t.datetime "created_on", precision: nil
    t.integer "created_by_id", default: 0, null: false
    t.boolean "is_private", default: false, null: false
    t.index ["project_id"], name: "index_tags_on_project_id"
    t.index ["rel_object_id", "rel_object_type"], name: "index_tags_on_rel_object_id_and_rel_object_type"
    t.index ["tag"], name: "index_tags_on_tag"
  end

  create_table "task_lists", force: :cascade do |t|
    t.integer "priority"
    t.integer "milestone_id"
    t.integer "project_id"
    t.string "name", limit: 100
    t.text "description"
    t.boolean "is_private", default: false, null: false
    t.datetime "completed_on", precision: nil
    t.integer "completed_by_id"
    t.datetime "created_on", precision: nil
    t.integer "created_by_id", default: 0, null: false
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id", default: 0, null: false
    t.integer "order", limit: 3, default: 0, null: false
    t.index ["completed_on"], name: "index_task_lists_on_completed_on"
    t.index ["created_on"], name: "index_task_lists_on_created_on"
    t.index ["milestone_id"], name: "index_task_lists_on_milestone_id"
    t.index ["project_id"], name: "index_task_lists_on_project_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "task_list_id"
    t.text "text"
    t.integer "assigned_to_company_id", limit: 8, default: 0, null: false
    t.integer "assigned_to_user_id", limit: 8, default: 0, null: false
    t.datetime "completed_on", precision: nil
    t.integer "completed_by_id"
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.integer "order", default: 0, null: false
    t.integer "comments_count", default: 0
    t.float "estimated_hours"
    t.integer "project_id"
    t.index ["completed_on"], name: "index_tasks_on_completed_on"
    t.index ["created_on"], name: "index_tasks_on_created_on"
    t.index ["order"], name: "index_tasks_on_order"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["task_list_id"], name: "index_tasks_on_task_list_id"
  end

  create_table "time_records", force: :cascade do |t|
    t.integer "project_id"
    t.integer "task_list_id"
    t.integer "task_id"
    t.string "name", limit: 100
    t.text "description"
    t.datetime "done_date", precision: nil
    t.float "hours", default: 0.0, null: false
    t.boolean "is_billable", default: true, null: false
    t.integer "assigned_to_company_id", default: 0, null: false
    t.integer "assigned_to_user_id", default: 0, null: false
    t.boolean "is_private", default: false, null: false
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.integer "updated_by_id"
    t.datetime "start_date", precision: nil
    t.index ["created_on"], name: "index_time_records_on_created_on"
    t.index ["done_date"], name: "index_time_records_on_done_date"
    t.index ["project_id"], name: "index_time_records_on_project_id"
  end

  create_table "user_im_values", force: :cascade do |t|
    t.integer "user_id", default: 0, null: false
    t.integer "im_type_id", limit: 3, default: 0, null: false
    t.string "value", limit: 50, default: "", null: false
    t.boolean "is_default", default: false, null: false
    t.index ["is_default"], name: "index_user_im_values_on_is_default"
  end

  create_table "users", force: :cascade do |t|
    t.integer "company_id", limit: 8, default: 0, null: false
    t.string "username", limit: 50, default: "", null: false
    t.string "email", limit: 100
    t.string "token", limit: 40, default: "", null: false
    t.string "salt", limit: 13, default: "", null: false
    t.string "twister", limit: 10, default: "", null: false
    t.string "display_name", limit: 50
    t.string "title", limit: 30
    t.string "office_number", limit: 20
    t.string "fax_number", limit: 20
    t.string "mobile_number", limit: 20
    t.string "home_number", limit: 20
    t.datetime "created_on", precision: nil, null: false
    t.integer "created_by_id"
    t.datetime "updated_on", precision: nil
    t.datetime "last_login", precision: nil
    t.datetime "last_visit", precision: nil
    t.datetime "last_activity", precision: nil
    t.boolean "is_admin", default: false, null: false
    t.boolean "auto_assign", default: false, null: false
    t.string "office_number_ext", limit: 5
    t.string "time_zone", default: "", null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.string "remember_token", limit: 40
    t.datetime "remember_token_expires_at", precision: nil
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_login"], name: "index_users_on_last_login"
    t.index ["last_visit"], name: "index_users_on_last_visit"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "wiki_pages", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.boolean "main", default: false, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "project_id"
    t.integer "created_by_id"
    t.string "slug"
    t.boolean "current_revision", default: false
    t.integer "revision_number", default: 0
    t.index ["current_revision"], name: "index_wiki_pages_on_current_revision"
    t.index ["main"], name: "index_wiki_pages_on_main"
    t.index ["project_id"], name: "index_wiki_pages_on_project_id"
    t.index ["revision_number"], name: "index_wiki_pages_on_revision_number"
    t.index ["slug"], name: "index_wiki_pages_on_slug"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
