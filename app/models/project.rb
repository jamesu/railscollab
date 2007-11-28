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

class Project < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_many :project_users
	has_many :users, :through=> :project_users
	
	has_many :project_times, :dependent => :destroy
	has_many :tags, :as => :rel_object # Dependent objects sould destroy all of these for us
	
	has_many :project_milestones, :dependent => :destroy do
		def open(reload=false)
			# Grab open milestones only
			find(:all, :conditions => 'project_milestones.completed_on IS NULL', :order => 'project_milestones.due_date ASC')
		end
		
		def late(reload=false)
			find(:all, :conditions => "due_date < '#{Date.today}' AND completed_on IS NULL")
		end
		
		def todays(reload=false)
			find(:all, :conditions => "completed_on IS NULL AND (due_date >= '#{Date.today}' AND due_date < '#{Date.today+1}')")
		end
		
		def upcomming(reload=false)
			find(:all, :conditions => "completed_on IS NULL AND due_date >= '#{Date.today+1}'")
		end
		
		def completed(reload=false)
			find(:all, :conditions => 'completed_on IS NOT NULL')
		end
	end
	
	has_many :project_task_lists, :order => '"order" DESC', :dependent => :destroy do
		def open(reload=false)
			# Grab open task lists only
			find(:all, :conditions => 'project_task_lists.completed_on IS NULL')
		end
		
		def completed(reload=false)
			# Grab completed task lists only
			find(:all, :conditions => 'project_task_lists.completed_on IS NOT NULL')
		end
	end
	
	has_many :project_forms, :order => '"order" DESC', :dependent => :destroy do
		def visible(reload=false)
			# Grab visible forms only
			find(:all, :conditions => ['project_forms.is_visible = ?', true])
		end
	end
	
	has_many :project_folders, :dependent => :destroy
	has_many :project_files, :dependent => :destroy do
		def important(reload=false)
			find(:all, :conditions => ['is_important = ?', true])
		end
	end
	has_many :project_messages, :dependent => :destroy do
		def important(reload=false)
			find(:all, :conditions => ['is_important = ?', true])
		end
	end
	has_many :project_message_categories, :dependent => :destroy
	
	has_many :application_logs, :order => 'created_on DESC, id DESC', :dependent => :destroy do
		def public(reload=false)
			# Grab public logs only
			@public_application_logs = nil if reload
			@public_application_logs ||= find(:all, :conditions => ['is_private = ?', false])
		end
	end
	
	has_and_belongs_to_many :companies, :join_table => :project_companies
	
	before_create  :process_params
	after_create   :process_create
	before_update  :process_update_params
	before_destroy :process_destroy
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	  write_attribute("completed_on", nil)
	end
	
	def process_create
	  ApplicationLog.new_log(self, self.created_by, :add, true)
	end
	
	def process_update_params
	  if @update_completed.nil?
		write_attribute("updated_on", Time.now.utc)
		ApplicationLog::new_log(self, self.updated_by, :edit, true)
	  else
		write_attribute("completed_on", @update_completed ? Time.now.utc : nil)
		self.completed_by = @update_completed_user
		ApplicationLog::new_log(self, @update_completed_user, @update_completed ? :close : :open, true)
	  end
	end
	
	def process_destroy
	  ActiveRecord::Base.connection.execute("DELETE FROM project_users WHERE project_id = #{self.id}")
	  ApplicationLog.new_log(self, self.updated_by, :delete, true)
	end
	
	def object_name
		self.name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'project', :action => 'overview', :active_project => self.id
	end
	
	def tasks_by_user(user, completed=false)
	    # TODO: need join on project task list
		ProjectTask.find(:all, :conditions => ["((assigned_to_company_id = ? OR assigned_to_user_id = ?) OR (assigned_to_company_id = 0 OR assigned_to_user_id = 0)) AND completed_on #{completed ? 'IS NOT' : 'IS'} NULL", user.company_id, user.id])
	end
	
	def is_active?
	    return self.completed_on == nil
	end
	
	def milestones_by_user(user, completed=false)
		ProjectMilestone.find(:all, :conditions => ["project_id = #{self.id} AND ((assigned_to_company_id = ? OR assigned_to_user_id = ?) OR (assigned_to_company_id = 0 OR assigned_to_user_id = 0)) AND completed_on #{completed ? 'IS NOT' : 'IS'} NULL", user.company_id, user.id])
	end
	
	def has_member(user)
	 return ProjectUser.find(:first, :conditions => "project_id = #{self.id} AND user_id = #{user.id}", :select => 'user_id')
	end
	
	def set_completed(value, user=nil)
	 @update_completed = value
	 @update_completed_user = user
	end
	
	# Core Permissions
	
	def self.can_be_created_by(user)
	 return (user.member_of_owner? and user.is_admin)
	end
	
	def can_be_edited_by(user)
	 return (user.member_of_owner? and user.is_admin)
	end
	
	def can_be_deleted_by(user)
	 return (user.member_of_owner? and user.is_admin)
	end
	
	def can_be_seen_by(user)
	 return (self.has_member(user) or user.is_admin)
	end
	
	# Specific Permissions
	
	def can_be_managed_by(user)
	 return (user.owner_of_owner? or user.is_admin?)
	end
	
	def company_can_be_removed_by(company, user)
	 if company.is_owner?
	   return false
	 else
	   return (user.owner_of_owner? or user.is_admin?)
	 end
	end
	
	def user_can_be_removed_by(user_remove, user)
	 if user_remove.owner_of_owner?
	   return false
	 end
	 
	 return (user.owner_of_owner? or user.is_admin)
	end
	
	def status_can_be_changed_by(user)
	 return (user.owner_of_owner? or user.is_admin?)
	end
	
	# Helpers
	
	def self.select_list
	 Project.find(:all).collect do |project|
	   [project.name, project.id]
	 end
	end
	
	# Accesibility
	
	attr_accessible :name, :description, :priority, :show_description_in_overview
	
	# Validation
	
	validates_presence_of :name
end
