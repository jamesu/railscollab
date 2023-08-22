class RemoveCrap < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "searchable_objects"
  end

  def self.down
    create_table "searchable_objects", :id => false, :force => true do |t|
        t.string  "rel_object_type", :limit => 50
        t.integer "rel_object_id",   :limit => 10, :default => 0,     :null => false
        t.string  "column_name",     :limit => 50, :default => "",    :null => false
        t.text    "content",                                          :null => false
        t.integer "project_id",      :limit => 10, :default => 0,     :null => false
        t.boolean "is_private",                    :default => false, :null => false
    end

    add_index "searchable_objects", ["project_id"], :name => "index_searchable_objects_on_project_id"
    add_index "searchable_objects", ["rel_object_id", "rel_object_type"], :name => "index_searchable_objects_on_rel_object_id_and_rel_object_type"    
  end
end
