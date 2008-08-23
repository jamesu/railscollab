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

class ProjectTime < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project
	
	belongs_to :company, :foreign_key => 'assigned_to_company_id'
	belongs_to :user, :foreign_key => 'assigned_to_user_id'
	
	belongs_to :project_task_list, :foreign_key => 'task_list_id'
	belongs_to :project_task, :foreign_key => 'task_id'
	
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_many :project_messages, :foreign_key => 'milestone_id'
	
	#has_many :tags, :as => 'rel_object', :dependent => :destroy
	
	acts_as_ferret :fields => [:name, :description, :project_id, :is_private, :tags_with_spaces], :store_class_name => true
	
	before_validation_on_create  :process_params
	after_create   :process_create
	before_update  :process_update_params
	before_destroy :process_destroy
	 
	def process_params
	  if self.assigned_to_user_id.nil?
	   write_attribute("assigned_to_user_id", 0)
	  end
	  if self.assigned_to_company_id.nil?
	    write_attribute("assigned_to_company_id", 0)
	  end
	end
	
	def process_create
	  ApplicationLog::new_log(self, self.created_by, :add, self.is_private)
	end
	
	def process_update_params
	  if self.assigned_to_user_id.nil?
		write_attribute("assigned_to_user_id", 0)
	  end
	  if self.assigned_to_company_id.nil?
		write_attribute("assigned_to_company_id", 0)
	  end
	  
	  ApplicationLog::new_log(self, self.updated_by, :edit, self.is_private)
	end
	
	def process_destroy
	  Tag.clear_by_object(self)
	  ApplicationLog.new_log(self, self.updated_by, :delete, self.is_private)
	end
	
	def object_name
		self.name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'time', :action => 'view', :id => self.id, :active_project => self.project_id
	end
	
	# Responsible party assignment
	
	def open_task=(obj)
		self.project_task_list = obj.nil? ? nil : obj.task_list
		self.project_task = obj
	end
	
	def open_task
		self.project_task
	end
	
	def open_task_id=(val)
        # Set open_task accordingly
		if (val.nil? || val == '0')
			self.open_task = nil
			return
		end
		
		self.open_task = ProjectTask.find(val)
	end
	
	def open_task_id
		if !self.project_task.nil?
			self.project_task.id.to_s
		else
			"0"
		end
	end
	
	# Task list / task assignment
	
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
	
	def tags
	 return Tag.list_by_object(self).join(',')
	end
	
	def tags_with_spaces
	 return Tag.list_by_object(self).join(' ')
	end
	
	def tags=(val)
	 Tag.clear_by_object(self)
	 Tag.set_to_object(self, val.split(',')) unless val.nil?
	end
	
	def is_today?
		return self.done_date.to_date == Date.today
	end
	
	def is_yesterday?
		return self.done_date.to_date == Date.today-1
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
	
	def self.find_by_task_list(params, time_conds, time_order=nil)
	   lists = []
	   
	   ProjectTaskList.find(:all, :params).each do |list|
	       tasks = []
	       list.project_tasks.each do |task|
	         total = ProjectTime.sum(:hours, :conditions => ['task_list_id = ? AND task_id = ?', list.id, task.id])
	         if (!total.nil? and total > 0)
	           extra_conditions = time_conds.clone.merge({'task_list_id' => list.id, 'task_id' => task.id})
	           tasks << {:task => task, :hours => total, :list => ProjectTime.find(:all, :conditions => extra_conditions, :order => time_order)}
	         end
	       end
	       
	       lists << {:list => list, :tasks => tasks}
	   end
	   
	   return lists
	end
	
	def self.find_grouped(group_field, params)
		grouped_fields = {}
		found_times = ProjectTime.find(:all, params)
		
		group_type = ProjectTime if ['assigned_to','project','project_task','project_task_list'].include?(group_field)
		group_type ||= String
		
		found_times.each do |time|
			dest_str = nil
			
			if group_type == ProjectTime
				dest_str = time[group_field].object_name
			else
				dest_str = time[group_field].to_s[0..0]
			end
			
			grouped_fields[dest_str] ||= []
			grouped_fields[dest_str] << file
		end
		
		return found_times, grouped_fields
	end
	
	def self.all_by_user(user)
		projects = user.active_projects
		
		project_ids = projects.collect do |p|
			p.id
		end.join ','
		
		if project_ids.length == 0
			return []
		end
		
		time_conditions = user.member_of_owner? ?
		                 ["project_id IN (#{project_ids})"] :
		                 ["project_id IN (#{project_ids}) AND is_private = ?", false]
		
		return self.find(:all, :conditions => time_conditions)
	end
	
	# Core Permissions
	
	def self.can_be_created_by(user, project)
	  project.is_active? and user.has_permission(project, :can_manage_time)
	end
	
	def can_be_edited_by(user)
	 return false if (!user.member_of(project))
	 return ((user.is_admin or created_by.id == user.id) and project.is_active?)
	end
	
	def can_be_deleted_by(user)
	 project.is_active? and user.member_of(project) and user.is_admin
	end
	
	def can_be_seen_by(user)
	 if !project.has_member(user)
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_time)
	   return true
	 end
	 
	 if self.is_private and !user.member_of_owner?
	   return false
	 end
	 
	 return true
	end
	
	# Specific Permissions

    def can_be_managed_by(user)
      project.is_active? and user.has_permission(project, :can_manage_time)
    end
	
	# Accesibility
	
	attr_accessible :name, :description, :done_date, :hours, :open_task_id, :assigned_to_id, :is_private, :is_important
	
	# Validation
	
	validates_presence_of :name
	validates_each :is_private, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
		record.errors.add attr, :not_allowed.l if value == true
	end
	
	validates_each :assigned_to, :allow_nil => true do |record, attr, value|
		record.errors.add attr, :not_part_of_project.l if (!value.nil? and !value.is_part_of(record.project))
	end
end

