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

class ProjectForm < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project

	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	before_create  :process_params
	after_create   :process_create
	before_update  :process_update_params
	before_destroy :process_destroy
  
	@@action_lookup = {:unknown => 0, :add_comment => 1, :add_task => 2}
	@@action_id_lookup = @@action_lookup.invert
	
	def process_params
	end
	
	def process_create
	  ApplicationLog::new_log(self, self.created_by, :add)
	end
	
	def process_update_params
	  ApplicationLog::new_log(self, self.updated_by, :edit)
	end
	
	def process_destroy
	  ApplicationLog::new_log(self, self.updated_by, :delete)
	end
	
	def object_name
		self.name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'form', :action => 'submit', :id => self.id, :active_project => self.project_id
	end
  
	def action
		@@action_id_lookup[self.action_id]
	end
  
	def action=(val)
		self.action_id = @@action_lookup[val.to_sym]
	end
	
	def in_object
		return nil if (self.in_object_id == nil or self.in_object_id == 0)
		
		begin
			if self.action == :add_comment
				ProjectMessage.find(self.in_object_id)
			elsif self.action == :add_task
				ProjectTaskList.find(self.in_object_id)
			else
				nil
			end
		rescue ActiveRecord::RecordNotFound
			nil
		end
	end
	
	def in_object=(value)
		write_attribute("in_object_id", value.id)
	end
	
	def self.priv_scope(include_private)
	  if include_private
	    yield
	  else
	    with_scope :find => { :conditions =>  ['is_visible = ?', true] } do 
	      yield 
	    end
	  end
	end
	
	# Assignment for actions
	
	def add_comment_object
		self.action == :add_comment ? self.in_object_id : 0
	end
	
	def add_comment_object=(val)
		if self.action == :add_comment
			self.in_object_id = val
		end
	end
	
	def add_task_object
		self.action == :add_task ? self.in_object_id : 0
	end
	
	def add_task_object=(val)
		if self.action == :add_task
			self.in_object_id = val
		end
	end
		
	# Core Permissions
	
	def self.can_be_created_by(user, project)
	 project.is_active? and (user.member_of(project) and user.is_admin)
	end
	
	def can_be_edited_by(user)
	 project.is_active? and user.member_of(project) and user.is_admin
    end

	def can_be_deleted_by(user)
	 project.is_active? and user.member_of(project) and user.is_admin
    end
    
	def can_be_seen_by(user)
	 user.member_of(project)
    end
	
	# Specific Permissions

	def can_be_submitted_by(user)
	 return (self.is_enabled and project.is_active? and user.member_of(project))
	end
	
	# Helpers
	
	def submit(attribs, user)
		rel_object = self.in_object
		
		if !rel_object.nil?
			# Note that this might be better as a case if there were more than 2 actions
			if self.action == :add_comment
				new_comment = Comment.new(:text => attribs[:content])
				new_comment.rel_object = rel_object
				new_comment.created_by = user
				
				if new_comment.save
					ApplicationLog.new_log(new_comment, @logged_user, :add, rel_object.is_private, rel_object.project)
					true
				else
					false
				end
			elsif self.action == :add_task
				new_task = ProjectTask.new(:text => attribs[:content])
				new_task.task_list = rel_object
				new_task.created_by = user
				
				if new_task.save
					ApplicationLog.new_log(new_task, @logged_user, :add, rel_object.is_private, rel_object.project)
					true
				else
					false
				end
			end
		else
			false
		end
	end
	
	# Accesibility
	
	attr_accessible :name, :description, :success_message, :action, :is_enabled, :is_visible, :add_comment_object, :add_task_object
	
	# Validation
	
	validates_presence_of :name
end
