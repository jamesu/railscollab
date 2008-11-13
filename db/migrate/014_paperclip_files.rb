class PaperclipFiles < ActiveRecord::Migration
  def self.up
    add_column :project_file_revisions, "data_file_name",    :string
    add_column :project_file_revisions, "data_content_type", :string
    add_column :project_file_revisions, "data_file_size",    :integer
    add_column :project_file_revisions, 'data_updated_at',   :datetime
    add_column :project_file_revisions, 'has_thumbnail',     :boolean, :default => false
    
    drop_table :file_repo
    remove_column :project_file_revisions, 'repository_id'
    remove_column :project_file_revisions, 'thumb_filename'
  end

  def self.down
    add_column :project_file_revisions, 'repository_id',   :string, :limit => 40, :default => "", :null => false
    add_column :project_file_revisions, 'thumb_filename',  :string, :limit => 44
    
    create_table :file_repo do |t|
      t.binary  "content",                                :null => false
      t.integer "order",                   :default => 0, :null => false
      t.integer "storage_id", :limit => 1, :default => 0, :null => false
    end
    
    remove_column :project_file_revisions, "data_file_name"
    remove_column :project_file_revisions, "data_content_type"
    remove_column :project_file_revisions, "data_file_size"
    remove_column :project_file_revisions, 'data_updated_at'
    remove_column :project_file_revisions, 'has_thumbnail'
  end
end
