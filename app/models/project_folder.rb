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

class ProjectFolder < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project
	
	has_many :project_files, :foreign_key => 'folder_id'
	
	def object_name
		self.name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'files', :action => 'browse_folder', :id => self.id, :active_project => self.project_id
	end
		
	# Core Permissions
	
	def self.can_be_created_by(user, project)
	  project.is_active? and user.has_permission(project, :can_manage_files)
	end
	
	def can_be_edited_by(user)
	  project.is_active? and user.has_permission(project, :can_manage_files)
	end
	
	def can_be_deleted_by(user)
	  project.is_active? and user.has_permission(project, :can_manage_files)
	end
	
	def can_be_seen_by(user)
	  project.has_member(user)
	end
	
	# Specific Permissions

    def can_be_managed_by(user)
	 project.is_active? and user.has_permission(project, :can_manage_files)
    end
    
    # Helpers
    
	def self.select_list(project)
	   [['None', 0]] + ProjectFolder.find(:all, :conditions => "project_id = #{project.id}", :select => 'id, name').collect do |folder|
	      [folder.name, folder.id]
	   end
	end
	
	# Accesibility
	
	attr_accessible :name
	
	# Validation
	
	validates_presence_of :name
	validates_uniqueness_of :name, :scope => :project_id
end
