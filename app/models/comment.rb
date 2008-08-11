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

class Comment < ActiveRecord::Base
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	belongs_to :rel_object, :polymorphic => true, :counter_cache => true
	
	has_many :attached_file, :as => 'rel_object'
	has_many :project_file, :through => :attached_file
	
	acts_as_ferret :fields => [:text, :project_id, :is_private], :store_class_name => true

	before_validation_on_create :process_params
	after_create :process_create
	before_update :process_update_params
	before_destroy :process_destroy
	 
	def process_params
	  self.is_anonymous = self.created_by.is_anonymous?
	  
	  true
	end
	
	def process_create
	  ApplicationLog.new_log(self, self.created_by, :add, self.is_private, self.rel_object.project)
	end
	
	def process_update_params
	  ApplicationLog.new_log(self, self.updated_by, :edit, self.is_private, self.rel_object.project)
	end
	
	def process_destroy
      AttachedFile.clear_attachments(self)
	  ApplicationLog.new_log(self, self.updated_by, :delete, true,  self.rel_object.project)
	end
	
	def last_edited_by_owner?
	 return (self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?))
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
		
	# Core Permissions
	
	def self.can_be_created_by(user, project)
	 false
	end
	
	def can_be_edited_by(user)
	  comment_project = self.rel_object.project
	  
	  if comment_project.is_active? and comment_project.has_member(user)
	    return true if (user.member_of_owner? and user.is_admin)
	  	
	  	if self.created_by == user and !user.is_anonymous?
	  		now = Time.now.utc
		    return (now <= (self.created_on + (60 * AppConfig.minutes_to_comment_edit_expire)))
	    end
	  end
	  
	  return false
	end
	
	def can_be_deleted_by(user)
	 return self.rel_object.can_be_deleted_by(user)
	end
	
	def can_be_seen_by(user)
	 return false if (self.is_private and !user.member_of_owner?)
	 
	 self.rel_object.can_be_seen_by(user)
	end
	
	# Specific permissions
    
    def file_can_be_added_by(user)
      return (self.can_be_edited_by(user) and user.has_permission(self.rel_object.project, :can_upload_files))
    end
    
    # Helpers

	def object_name
		self.text.excerpt(50)
	end
	
	def object_url
		if self.rel_object
			self.rel_object.object_url + "#objectComments"
		else
			""
		end
	end
	
	def project
		self.rel_object.project
	end
	
	def project_id
		self.rel_object.project_id
	end
	
	def attached_files(with_private)
		self.project_file
	end
	
	# Accesibility
	
	attr_accessible :text, :is_private, :author_name, :author_email
	
	# Validation
	
	validates_presence_of :author_name, :if => Proc.new { |obj| obj.is_anonymous }
	validates_presence_of :author_email, :if => Proc.new { |obj| obj.is_anonymous }
	
	validates_presence_of :text
	validates_each :is_private, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
		record.errors.add attr, :not_allowed.l if value == true
	end
end
