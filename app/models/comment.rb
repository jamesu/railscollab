=begin
RailsCollab
-----------
Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class Comment < ActiveRecord::Base
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	belongs_to :rel_object, :polymorphic => true
	
	has_many :attached_file, :as => 'rel_object', :dependent => :destroy
	has_many :project_file, :through => :attached_file

	before_create :process_params
	before_update :process_update_params
	before_destroy :process_destroy
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	end
	
	def process_update_params
      write_attribute("updated_on", Time.now.utc)
	end
	
	def process_destroy
      AttachedFile.clear_attachments(self)
	end
		
	# Core Permissions
	
	def self.can_be_created_by(user, project)
	 false
	end
	
	def can_be_edited_by(user)
	  comment_project = self.rel_object.project
	  
	  if comment_project.has_member(user)
	    return true if (user.member_of_owner? and user.is_admin)
	  	
	  	if self.created_by == user
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
		"Comment #{self.id}"
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
	
	def attached_files(with_private)
		self.project_file
	end
	
	# Accesibility
	
	attr_accessible :text
	
	# Validation
	
	validates_presence_of :text
end
