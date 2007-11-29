=begin
RailsCollab
-----------

Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

require 'gd2'

class ProjectFileRevision < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project_file, :foreign_key => 'file_id'
	belongs_to :file_type, :foreign_key => 'file_type_id'

	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	acts_as_ferret :fields => [:comment, :project_id, :is_private], :store_class_name => true
	
	before_create :process_params
	before_update :process_update_params
	before_destroy :process_destroy
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	end
	
	def process_update_params
	  write_attribute("updated_on", Time.now.utc)
	  ApplicationLog::new_log(self, self.updated_by, :edit, self.project_file.is_private, self.project_file.project)
	end
	
	def process_destroy
	  # Destroy FileRepo entries
	  FileRepo.handle_delete(self.repository_id)
	  ApplicationLog::new_log(self, self.updated_by, :delete, self.project_file.is_private, self.project_file.project)
	end
	
	def upload_file
		nil
	end
	
	def upload_file=(value)
		self.filesize = value.size
		self.type_string = value.content_type.chomp
		
		# Figure out the intended file type
		extension = value.original_filename.split('.', 2)[-1]
		self.file_type = FileType.find(:first, :conditions => ['extension = ?', extension])
		self.file_type ||= FileType.find(:first, :conditions => 'extension = \'txt\'')
		
		# Store to the repository
		if self.new_record?
			self.repository_id = FileRepo.handle_storage(value.read)
		else
			self.repository_id = FileRepo.handle_update(self.repository_id, value.read)
		end
		
		self.update_thumb if !self.repository_id.nil?
	end
	
	def update_thumb
		FileRepo.handle_delete(self.thumb_filename) unless self.thumb_filename.nil?
		
		# Check if we can make a thumbnail
		if self.project_file.is_private || !['image/jpg', 'image/jpeg', 'image/gif', 'image/png'].include?(self.type_string)
			self.thumb_filename = nil
			return
		end

		max_width = AppConfig.max_thumbnail_width
		max_height = AppConfig.max_thumbnail_height
				
		# Now try to make it!
		image_data = FileRepo.get_data(self.repository_id)
		image = GD2::Image.load(image_data)
		
		image.resize!(image.width > max_width ? max_width : image.width,
					  image.height > max_height ? max_height : image.height)
		
		self.thumb_filename = FileRepo.handle_storage(image.jpeg(AppConfig.file_thumbnail_quality))
	end
	
	def filetype_icon_url
		if self.thumb_filename.nil?
			ext = self.file_type ? self.file_type.icon : "unknown.png"
			return "/images/filetypes/#{ext}"
		else
			return "/files/thumbnail/#{self.id}.jpg"
		end
	end
	
	def is_private
		self.project_file.is_private
	end
		
	def object_name
		self.project_file.filename
	end
	
	def object_url
		url_for :only_path => true, :controller => 'file', :action => 'browse_folder', :id => self.id, :active_project => self.project_id
	end
	
	def icon_url
		name = "unknown.png"
		return "/filetypes/#{name}"
	end
	
	# Validation
	
	#validates_presence_of :repository_id
end
