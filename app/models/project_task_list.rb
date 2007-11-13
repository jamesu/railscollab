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

class ProjectTaskList < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project_milestone, :foreign_key => 'milestone_id'
	belongs_to :project
	belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_many :project_tasks, :foreign_key => 'task_list_id', :dependent => :destroy
	
	has_many :tags, :as => 'rel_object', :dependent => :destroy
	
	before_create :process_params
	before_update :process_update_params
	
	def process_params
	  write_attribute("created_on", Time.now.utc)
	  write_attribute("completed_on", nil)
	end
	
	def process_update_params
	  write_attribute("updated_on", Time.now.utc)
	  
	  # Close task list if we have completed all tasks
	  if self.finished_all_tasks?
	   write_attribute("completed_on", Time.now.utc)
	  else
	   write_attribute("completed_on", nil)
	  end
	  
	end
	
	def object_name
		self.name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'task', :action => 'view_list', :id => self.id, :active_project => self.project_id
	end
	
	def tags
	 return Tag.list_by_object(self).join(',')
	end
	
	def tags=(val)
	 Tag.clear_by_object(self)
	 Tag.set_to_object(self, val.split(',')) unless val.nil?
	end
	
	def is_completed?
	 return self.completed_on != nil
	end
	
	def send_comment_notifications(comment)
	end

	def self.can_be_created_by(user, project)
	  user.has_permission(project, :can_manage_tasks)
	end
	
	def can_be_changed_by(user)
	 if (!self.project.has_member(user))
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
	 if !self.project.has_member(user)
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_tasks)
	   return true
	 end
	 
	 return false
	end
	
	def can_be_seen_by(user)
	 if !self.project.has_member(user)
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_tasks)
	   return true
	 end
	 
	 if self.is_private and !user.member_of_owner?
	   return false
	 end
	 
	 return true
	end
	
    def comment_can_be_added_by(user)
	 return self.project.has_member(user)
    end
	
	def open_tasks
	 self.project_tasks.reject do |task| not task.completed_on.nil? end
	end
	
	def completed_tasks
	 self.project_tasks.reject do |task| task.completed_on.nil? end
	end
	
	def finished_all_tasks?
	 completed_count = 0
	 
	 self.project_tasks.each do |task|
	   completed_count += 1 unless task.completed_on.nil?
	 end
	 
	 return (completed_count > 0 and completed_count == self.project_tasks.length)
	end
	
	def self.select_list(project)
	   ProjectTaskList.find(:all, :conditions => "project_id = #{project.id}", :select => 'id, name').collect do |tasklist|
	      [tasklist.name, tasklist.id]
	   end
	end
	
	# Accesibility
	
	attr_accessible :name, :priority, :description, :milestone_id
	
	# Validation
	
	validates_presence_of :name
end
