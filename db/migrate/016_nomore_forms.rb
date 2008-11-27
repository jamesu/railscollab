class NomoreForms < ActiveRecord::Migration
  def self.up
    drop_table 'project_forms'
  end

  def self.down
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
  end
end