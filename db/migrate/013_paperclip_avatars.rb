class PaperclipAvatars < ActiveRecord::Migration
  def self.up
    remove_column :companies, 'logo_file'
    remove_column :users, 'avatar_file'
    
    add_column :companies, "logo_file_name",    :string
    add_column :companies, "logo_content_type", :string
    add_column :companies, "logo_file_size",    :integer
    add_column :companies, 'logo_updated_at',   :datetime
    
    add_column :users, "avatar_file_name",    :string
    add_column :users, "avatar_content_type", :string
    add_column :users, "avatar_file_size",    :integer
    add_column :users, 'avatar_updated_at',   :datetime
  end

  def self.down
    add_column :companies, 'logo_file',     :string, :limit => 44
    add_column :users, 'avatar_file',       :string, :limit => 44
    
    remove_column :companies, "logo_file_name"
    remove_column :companies, "logo_content_type"
    remove_column :companies, "logo_file_size"
    remove_column :companies, 'logo_updated_at'
    
    remove_column :users, "avatar_file_name"
    remove_column :users, "avatar_content_type"
    remove_column :users, "avatar_file_size"
    remove_column :users, 'avatar_updated_at'
  end
end
