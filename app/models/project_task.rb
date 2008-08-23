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

class ProjectTask < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :task_list, :class_name => 'ProjectTaskList', :foreign_key => 'task_list_id'
	
	belongs_to :company, :foreign_key => 'assigned_to_company_id'
	belongs_to :user, :foreign_key => 'assigned_to_user_id'
	
	belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'
	
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_many :project_times, :foreign_key => 'task_id', :dependent => :nullify
	
	acts_as_ferret :fields => [:text, :project_id, :is_private], :store_class_name => true

	before_validation_on_create  :process_params
	after_create   :process_create
	before_update  :process_update_params
	after_update   :update_task_list
	before_destroy :process_destroy
	 
	def process_params
	  write_attribute("completed_on", nil)
	  write_attribute("order", self.task_list.project_tasks.length)
	end
	
	def process_create
	  self.task_list.ensure_completed(!self.completed_on.nil?, self.created_by)
	  ApplicationLog.new_log(self, self.created_by, :add, self.task_list.is_private, self.task_list.project)
	end
	
	def process_update_params
	  if @update_completed.nil?
		if @update_is_minor.nil?
			ApplicationLog.new_log(self, self.updated_by, :edit, self.task_list.is_private, self.task_list.project)
		end
	  else
		write_attribute("completed_on", @update_completed ? Time.now.utc : nil)
		self.completed_by = @update_completed_user
		ApplicationLog::new_log(self, @update_completed_user, @update_completed ? :close : :open, self.task_list.is_private, self.task_list.project)
	  end
	end
	
	def process_destroy
	  ApplicationLog.new_log(self, self.updated_by, :delete, true, self.task_list.project)
	end
	
	def update_task_list
	  if !@update_completed.nil?
		task_list = self.task_list
		
		task_list.ensure_completed(@update_completed, self.completed_by)
		task_list.save!
	  end
	end
	
	def object_name
		self.text
	end
	
	def object_url
		"#{self.task_list.object_url}#openTasksList#{self.task_list_id}_#{self.id}"
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
		if (val.nil? or val == '0' or val == 'c0')
			self.assigned_to = nil
			return
		end
		
		begin
		  self.assigned_to = val[0] == 99 ? 
		                   Company.find(val[1...val.length]) :
						   User.find(val)
		rescue ActiveRecord::RecordNotFound
		  self.assigned_to = nil
		end
	end
	
	def assigned_to_id
		if self.company
			"c#{self.company.id}"
		elsif self.user
			self.user.id.to_s
		else
			"0"
		end
	end
	
	def last_editor
	   self.updated_by || self.created_by
	end
	
	def is_private
		self.task_list.is_private
	end
	
	def project_id
		self.task_list.project_id
	end
	
	def send_comment_notifications(comment)
	end
	
	def set_completed(value, user=nil)
	 @update_completed = value
	 @update_completed_user = user
	end
	
	def set_order(value, user=nil)
	  @update_is_minor = true
	  self.order = value
	  self.updated_by = user unless user.nil?
	end
	
	def self.can_be_created_by(user, task_list)
	 return (task_list.project.is_active? and user.member_of(task_list.project) and (!(task_list.is_private and !user.member_of_owner?) and task_list.can_be_managed_by(user)))
	end
	
	def can_be_changed_by(user)
	 project = task_list.project
	 
	 return false if !user.member_of(project) or !project.is_active? or user.is_anonymous?
	 return true if user.is_admin
	 
	 task_assigned_to = assigned_to
	 return true if ((task_assigned_to == user) or (task_assigned_to == user.company) or task_assigned_to.nil?)
	 
	 # Owner editable for 3 mins
	 return true if (self.created_by_id == user.id and (self.created_on+(60*3)) < Time.now.utc)
	 
	 return task_list.can_be_changed_by(user)
	end
	
	def can_be_deleted_by(user)
	 task_list.can_be_deleted_by(user)
	end
	
	def can_be_seen_by(user)
	 return (can_be_changed_by(user) or task_list.can_be_seen_by(user))
	end
	
    def comment_can_be_added_by(user)
	 task_list.comment_can_be_added_by(user)
    end
	
	# Accesibility
	
	attr_accessible :text, :assigned_to_id, :task_list_id
	
	# Validation
	
	validates_presence_of :text
	
	validates_each :task_list, :allow_nil => false do |record, attr, value|
		record.errors.add attr, :not_part_of_project.l if (value.project_id != record.project_id) or !(value.can_be_changed_by(record.last_editor)) 
	end
	
	validates_each :assigned_to, :allow_nil => true do |record, attr, value|
		record.errors.add attr, :not_part_of_project.l if (!value.nil? and !value.is_part_of(record.task_list.project))
	end
end
