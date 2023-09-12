class PaperclipFiles < ActiveRecord::Migration[4.2]
  def self.up
    add_column :project_file_revisions, "data_file_name",    :string
    add_column :project_file_revisions, "data_content_type", :string
    add_column :project_file_revisions, "data_file_size",    :integer
    add_column :project_file_revisions, 'data_updated_at',   :datetime
    add_column :project_file_revisions, 'has_thumbnail',     :boolean, default: false
    
    # Migrate the data to the new system
    ProjectFileRevision.all.each do |file|
      repo = TempRepo.where({'id' => file.repository_id}).first
      unless repo.nil?
        puts "Migrating file #{file.project_file.filename} (revision #{file.id})"
        if repo.storage != :database
          puts "  WARNING: storage type #{repo.storage_id} for file #{repo.file_id} not handled"
        end

        # Grab data
        content = ActionController::UploadedTempfile.new("CGI")
        content.binmode if defined? content.binmode
        content.print repo.content
        content.content_type = file.type_string
        content.original_path = file.project_file.filename
        content.rewind

        # Store in new system
        file.upload_file = content
        file.save
      end
    end
    
    # Now we can drop the old stuff
    drop_table :file_repo
    remove_column :project_file_revisions, 'repository_id'
    remove_column :project_file_revisions, 'thumb_filename'
  end

  def self.down
    add_column :project_file_revisions, 'repository_id',   :string, limit: 40, default: "", null: false
    add_column :project_file_revisions, 'thumb_filename',  :string, limit: 44
    
    create_table :file_repo do |t|
      t.binary  "content",                                null: false
      t.integer "order",                   default: 0, null: false
      t.integer "storage_id", limit: 1, default: 0, null: false
    end
    
    # Ok, time to migrate data back to old system
    ProjectFileRevision.all.each do |file|
      puts "Migrating file #{file.project_file.filename} (revision #{file.id})"
      
      repo = TempRepo.new
      begin
        File.open(file.data.path, 'rb') do |io|
          repo.content = io.read
        end
      rescue Exception => e
        puts "  WARNING: couldn't migrate data #{e.to_s}"
        repo.content = ''
      end
      
      repo.storage_id = 0
      repo.save
      
      file.repository_id = repo.id
      file.save
    end
    
    
    remove_column :project_file_revisions, "data_file_name"
    remove_column :project_file_revisions, "data_content_type"
    remove_column :project_file_revisions, "data_file_size"
    remove_column :project_file_revisions, 'data_updated_at'
    remove_column :project_file_revisions, 'has_thumbnail'
  end
end

class TempRepo < ActiveRecord::Base
  self.table_name = 'file_repo'

  @@storage_lookup = {database: 0, :s3 => 1}
  @@storage_id_lookup = @@storage_lookup.invert

  def storage
    @@storage_id_lookup[self.storage_id]
  end
end