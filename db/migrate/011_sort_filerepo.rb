class SortFilerepo < ActiveRecord::Migration
  def self.up
    drop_table "file_repo_attributes"
    
    add_column :file_repo, :storage_id, :integer, :limit => 1, :default => 0, :null => false
  end

  def self.down
    create_table "file_repo_attributes" do |t|
      t.string "attribute", :limit => 50, :default => "", :null => false
      t.text   "value",                                   :null => false
    end
    
    remove_column :file_repo, :storage_id
  end
end
