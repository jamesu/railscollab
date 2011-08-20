#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
# Portions Copyright (C) René Scheibe
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class ProjectFileRevision < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :project_file, :foreign_key => 'file_id'
  belongs_to :file_type,    :foreign_key => 'file_type_id'

  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_attached_file :data, {
		:styles => { :thumb => "50x50" },
		:storage => AppConfig.attach_to_s3 ? :s3 : :filesystem,
		:default_url => ''
	}.merge(AppConfig.attach_to_s3 ? {
		:s3_credentials => {
			:access_key_id => AppConfig.s3_access_key,
			:secret_access_key => AppConfig.s3_secret_key
		},
		:path => ":attachment/:id/:style.:extension",
		:bucket => "#{AppConfig.s3_bucket_prefix}project_file_revision_data"
	} : {})

  before_create :process_params
  before_update :process_update_params
  before_destroy :process_destroy
  
  def project; self.project_file.project; end

  @@content_types = ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/jpg']
  def thumbnailable?(file)
    @@content_types.include?(file.content_type)
  end
    
  def process_params
  end

  def process_update_params
    ApplicationLog::new_log(self, self.updated_by, :edit, self.project_file.is_private, self.project_file.project)
  end

  def process_destroy
    ApplicationLog::new_log(self, self.updated_by, :delete, self.project_file.is_private, self.project_file.project)
  end

  def project_id
    self.project_file.project_id
  end

  def upload_file
    nil
  end

  def upload_file=(value)
    self.filesize = value.size
    value.content_type ||= 'text/data'
    self.type_string = value.content_type.chomp

    # Figure out the intended file type
    extension = value.original_filename.split('.', 2)[-1]
    self.file_type = FileType.first(:conditions => ['extension = ?', extension])
    self.file_type ||= FileType.first(:conditions => "extension = 'txt'")

    # Store
    self.data = value
    self.has_thumbnail = thumbnailable?(value)
  end

  def filetype_icon_url
    if !has_thumbnail
      ext = self.file_type ? self.file_type.icon : "unknown.png"
      return "/themes/#{AppConfig.site_theme}/images/filetypes/#{ext}"
    else
      data.url(:thumb)
    end
  end

  def is_private
    self.project_file.is_private
  end

  def object_name
    self.project_file.filename
  end

  def object_url(host = nil)
    (url_for hash_for_download_file_path(:only_path => host.nil?, :host => host, :id => self.id, :active_project => self.project_id)) + "\#revision#{self.id}"
  end

  def icon_url
    name = "unknown.png"
    return "/filetypes/#{name}"
  end

  # Validation

  #validates_presence_of :repository_id
end
