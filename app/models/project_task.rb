=begin
RailsCollab
-----------
Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class ProjectTask < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :task_list, :class_name => 'ProjectTaskList', :foreign_key => 'task_list_id'
	
	belongs_to :company, :foreign_key => 'assigned_to_company_id'
	belongs_to :user, :foreign_key => 'assigned_to_user_id'
	
	belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'
	
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_many :project_times, :foreign_key => 'task_id', :dependent => :nullify

	before_create :process_params
	before_update :process_update_params
	after_update  :update_task_list
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	  write_attribute("completed_on", nil)
	end
	
	def process_update_params
		write_attribute("updated_on", Time.now.utc)
	end
	
	def update_task_list
		task_list = self.task_list
		task_list.completed_by = self.completed_by
		task_list.save
	end
	
	def object_name
		self.text
	end
	
	def object_url
		url_for :only_path => true, :controller => 'task', :action => 'view', :id => self.id, :active_project => self.task_list.project
	end
		
	def assigned_to=(obj)
		self.company = obj.class == Company ? obj : nil
		self.user = obj.class == User ? obj : nil
	end

	def assigned_to
		if self.company
			self.company
		elsif self.user
			self.user
		else
			nil
		end
	end
	
	def assigned_to_id=(val)
        # Set assigned_to accordingly
        assign_id = val.to_i
        if assign_id == 0
        	self.assigned_to = nil
        elsif assign_id > 1000
          self.assigned_to = User.find(assign_id-1000)
        else
          self.assigned_to = Company.find(assign_id)
        end
	end
	
	def assigned_to_id
		if self.company
			self.company.id
		elsif self.user
			self.user.id+1000
		else
			0
		end
	end
	
	def self.can_be_created_by(user, project)
	  user.has_permission(project, :can_manage_tasks)
	end
	
	def can_be_changed_by(user)
	 project = self.task_list.project
	 
	 if (!project.has_member(user))
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_tasks)
	   return true
	 end
	 
	 if self.created_by == user
	   return true
	 end
	 
	 return false
	end
	
	def can_be_deleted_by(user)
	 project = self.task_list.project
	 
	 if !project.has_member(user)
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_tasks)
	   return true
	 end
	 
	 return false
	end
	
	def can_be_seen_by(user)
	 project = self.task_list.project
	 
	 if !project.has_member(user)
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_tasks)
	   return true
	 end
	 
	 if self.task_list.is_private and !user.member_of_owner?
	   return false
	 end
	 
	 return true
	end
	
    def comment_can_be_added_by(user)
	 return self.task_list.project.has_member(user)
    end
	
	# Accesibility
	
	attr_accessible :text, :assigned_to_id
	
	# Validation
	
	validates_presence_of :text
end
