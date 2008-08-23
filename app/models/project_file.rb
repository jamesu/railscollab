=begin
RailsCollab
-----------

Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)

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

class ProjectFile < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project
	belongs_to :project_folder, :foreign_key => 'folder_id', :counter_cache => true
	
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_many :project_file_revisions, :foreign_key => 'file_id', :order => 'revision_number DESC', :dependent => :destroy
	has_many :comments, :as => 'rel_object', :dependent => :destroy do
		def public(reload=false)
			# Grab public comments only
			@public_comments = nil if reload
			@public_comments ||= find(:all, :conditions => ['is_private = ?', false])
		end
	end
	#has_many :tags, :as => 'rel_object', :dependent => :destroy
	
	acts_as_ferret :fields => [:filename, :description, :project_id, :is_private, :tags_with_spaces], :store_class_name => true
	
	before_validation_on_create :process_params
	after_create  :process_create
	before_update :process_update_params
	before_destroy :process_destroy
	
	def process_params
	  write_attribute("comments_enabled", true) unless self.created_by.member_of_owner?
	end
	
	def process_create
	  ApplicationLog::new_log(self, self.created_by, :add)
	end
	
	def process_update_params
	  ApplicationLog::new_log(self, self.updated_by, :edit)
	end
	
	def process_destroy
	  Tag.clear_by_object(self)
	  AttachedFile.clear_files(self.id)
	  ApplicationLog::new_log(@file, self.updated_by, :delete)
	end
	
	def tags
	 return Tag.list_by_object(self).join(',')
	end
	
	def tags_with_spaces
	 return Tag.list_by_object(self).join(' ')
	end
	
	def tags=(val)
	 Tag.clear_by_object(self)
	 real_owner = project_file_revisions.empty? ? nil : self.project_file_revisions[0].created_by
	 Tag.set_to_object(self, val.split(','), real_owner) unless val.nil?
	end
	
	def last_created_by
		return project_file_revisions[0].created_by
	end
	
	def last_updated_by
		return project_file_revisions[0].updated_by
	end

	def object_name
	  return self.filename
	end
	
	def object_url
		url_for :only_path => true, :controller => 'files', :action => 'file_details', :id => self.id, :active_project => self.project_id
	end
	
	def download_url
		url_for :only_path => true, :controller => 'files', :action => 'download_file', :id => self.id, :active_project => self.project_id
	end
	
	def filetype_icon_url
		return project_file_revisions.empty? ? "/themes/#{AppConfig.site_theme}/images/filetypes/unknown.png" : project_file_revisions[0].filetype_icon_url
	end
	
	def file_size
		return project_file_revisions.empty? ? 0 : project_file_revisions[0].filesize
	end
	
	def last_revision
		return self.project_file_revisions[0]
	end
	
	def last_edited_by_owner?
	 return (self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?))
	end
	
	def send_comment_notifications(comment)
	end
	
	def self.priv_scope(include_private)
	  if include_private
	    yield
	  else
	    with_scope :find => { :conditions =>  ['is_private = ?', false] } do 
	      yield 
	    end
	  end
	end
	
	def add_revision(file, new_revision, user, comment)
		file_revision = ProjectFileRevision.new(:revision_number => new_revision)
		file_revision.project_file = self
		file_revision.upload_file = file
		
		file_revision.created_by = user
		file_revision.comment = comment
		
		file_revision.update_thumb
		
		file_revision.save!
		ApplicationLog::new_log(file_revision, user, :add, self.is_private, self.project) unless new_revision == 1
	end
	
	def update_revision(file, old_revision, user, comment)
		old_revision.upload_file = file
		
		old_revision.updated_by = user
		old_revision.comment = comment
		
		old_revision.update_thumb
		
		old_revision.save!
	end
	
	def self.handle_files(files, to_object, user, is_private)		
		count = 0
		
		if !files.nil?
			files.each do |file|
				if file.class != StringIO and 
				   file.class != ActionController::UploadedStringIO and
				   file.class != ActionController::UploadedTempfile
					count += 1
					next
				end
				
				filename = (file.original_filename).sanitize_filename
				
				ProjectFile.transaction do
					attached_file = ProjectFile.new()
					attached_file.filename = filename
					attached_file.is_private = is_private
					attached_file.is_visible = true
					attached_file.expiration_time = Time.now.utc
					attached_file.project = to_object.project
					attached_file.created_by = user
					
					if attached_file.save
						# Upload revision
						attached_file.add_revision(file, 1, user, "")
						to_object.project_file << attached_file
						
						count += 1
					
						ApplicationLog::new_log(attached_file, user, :add)
					end
				end
			end
		end
		
		return count
	end
	
	def self.find_grouped(group_field, params)
		grouped_fields = {}
		found_files = ProjectFile.find(:all, params)
		
		group_type = DateTime if ['created_on', 'updated_on'].include?(group_field)
		group_type ||= String
		
		today = Date.today
		
		found_files.each do |file|
			dest_str = nil
			
			if group_type == DateTime
				file_time = file[group_field]
				if file_time.year == today.year
					dest_str = file_time.strftime("%A, %d %B")
				else
					dest_str = file_time.strftime("%A, %d %B %Y")
				end
			else
				dest_str = file[group_field].to_s[0..0]
			end
			
			grouped_fields[dest_str] ||= []
			grouped_fields[dest_str] << file
		end
		
		return found_files, grouped_fields
	end
	
	def self.select_list(project, current_object=nil)
	   ids = current_object.nil? ? [] : current_object.project_file_ids
	   
	   [['--None--', 0]] + ProjectFile.find(:all, :conditions => ['project_id = ?', project.id], :select => 'id, filename').collect do |file|
	      if ids.include?(file.id)
	        nil
	      else
	        [file.filename, file.id]
	      end
	   end.compact
	end

    # Core permissions
    
	def self.can_be_created_by(user, project)
	  project.is_active? and user.has_permission(project, :can_upload_files)
	end
	
	def can_be_edited_by(user)
	 return false if (!project.is_active? or !(user.member_of(project) and user.has_permission(project, :can_manage_files)))
	 
	 return true if user.is_admin
	 
	 return (!(self.is_private and !user.member_of_owner?) and user.id == self.created_by.id)
    end

	def can_be_deleted_by(user)
	 user.is_admin and project.is_active? and user.member_of(project)
    end
    
	def can_be_seen_by(user)
	 return false if !user.member_of(self.project)
	 
	 return !(self.is_private and !user.member_of_owner?)
    end
	
	# Specific Permissions

    def can_be_managed_by(user)
      project.is_active? and user.has_permission(project, :can_manage_files)
    end
    
    def can_be_downloaded_by(user)
      can_be_seen_by(user)
    end
    
    def options_can_be_changed_by(user)
      return (user.member_of_owner? and can_be_edited_by(user))
    end
    
    def comment_can_be_added_by(user)
     if user.is_anonymous?
        return (self.anonymous_comments_enabled and project.is_active? and user.member_of(project) and !self.is_private)
     else
        return (self.comments_enabled and project.is_active? and user.member_of(project) and !(self.is_private and !user.member_of_owner?))
     end
    end
    
	# Accesibility
	
	attr_accessible :folder_id, :description, :is_private, :is_important, :comments_enabled, :anonymous_comments_enabled
	
	# Validation
	
	validates_presence_of :filename
	validates_each :project_folder, :allow_nil => true do |record, attr, value|
		record.errors.add attr, :not_part_of_project.l if value.project_id != record.project_id
	end
	
	validates_each :is_private, :is_important, :anonymous_comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
		record.errors.add attr, :not_allowed.l if value == true
	end
	
	validates_each :comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
		record.errors.add attr, :not_allowed.l if value == false
	end
end
