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

class ProjectMessage < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project_milestone, :foreign_key => 'milestone_id'
	belongs_to :project_message_category, :foreign_key => 'category_id', :counter_cache => true
	belongs_to :project
	
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	has_many :comments, :as => 'rel_object', :dependent => :destroy do
		def public(reload=false)
			# Grab public comments only
			@public_comments = nil if reload
			@public_comments ||= find(:all, :conditions => ['is_private = ?', false])
		end
	end
	has_many :tags, :as => 'rel_object', :dependent => :destroy
	has_many :attached_file, :as => 'rel_object', :dependent => :destroy
	
	has_many :project_file, :through => :attached_file
	
	has_and_belongs_to_many :subscribers, :class_name => 'User', :join_table => 'message_subscriptions', :foreign_key => 'message_id'
	
	acts_as_ferret :fields => [:title, :text, :additional_text, :project_id, :is_private], :store_class_name => true

	before_validation_on_create :process_params
	after_create  :process_create
	before_update :process_update_params
	before_destroy :process_destroy
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	  self.comments_enabled = true unless self.created_by.member_of_owner?
	end
	
	def process_create
	  ApplicationLog.new_log(self, self.created_by, :add, self.is_private)
	end
	
	def process_update_params
	  write_attribute("updated_on", Time.now.utc)
	  ApplicationLog.new_log(self, self.updated_by, :edit, self.is_private)
	end
	
	def process_destroy
	  AttachedFile.clear_attachments(self)
	  ApplicationLog.new_log(self, self.updated_by, :delete, self.is_private)
	end
	
	def tags
	 return Tag.list_by_object(self).join(',')
	end
	
	def tags=(val)
	 Tag.clear_by_object(self)
	 Tag.set_to_object(self, val.split(',')) unless val.nil?
	end
	
	def object_name
	  return self.title
	end
	
	def object_url
		url_for :only_path => true, :controller => 'message', :action => 'view', :id => self.id, :active_project => self.project_id
	end
	
	def attached_files(with_private)
		self.project_file
	end
	
	def send_comment_notifications(comment)
		self.subscribers.each do |subscriber|
			Notifier.deliver_message_comment(subscriber, comment, self)
		end
	end
	
	def last_edited_by_owner?
	 return (self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?))
	end
	
	def send_notification(user)
		Notifier.deliver_message(user, self)
	end
		
    # Core permissions
    
	def self.can_be_created_by(user, project)
	  user.has_permission(project, :can_manage_messages)
	end
	
	def can_be_edited_by(user)
	 if (!self.project.has_member(user))
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_messages) 
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
	 
	 if user.has_permission(project, :can_manage_messages)
	   return true
	 end
	 
	 return false
    end
    
	def can_be_seen_by(user)
	 if !self.project.has_member(user)
	   return false
	 end
	 
	 if self.is_private and !user.member_of_owner?
	   return false
	 end
	 
	 if user.has_permission(project, :can_manage_messages)
	   return true
	 end
	 
	 return true
    end
    
    # Message permissions
    
    def can_be_managed_by(user)
      return user.has_permission(self.project, :can_manage_messages)
    end
    
    def file_can_be_added_by(user)
      return user.has_permission(self.project, :can_upload_files)
    end
    
    def options_can_be_changed_by(user)
      return (user.member_of_owner? and self.can_be_edited_by(user))
    end
    
    def comment_can_be_added_by(user)
      return (user.member_of(self.project) and self.comments_enabled)
    end

	def self.select_list(project)
	   ProjectMessage.find(:all, :conditions => ['project_id = ?', project.id], :select => 'id, title').collect do |message|
	      [message.title, message.id]
	   end
	end
	
	# Accesibility
	
	attr_accessible :title, :text, :additional_text, :milestone_id, :category_id, :is_private, :is_important, :comments_enabled, :anonymous_comments_enabled
	
	# Validation
	
	validates_presence_of :title
	validates_presence_of :text
	validates_each :project_milestone, :allow_nil => true do |record, attr, value|
		record.errors.add attr, 'not part of project' if value.project_id != record.project_id
	end
	
	validates_each :project_message_category do |record, attr, value|
		record.errors.add attr, 'not part of project' if value.project_id != record.project_id
	end
	
	validates_each :is_private, :is_important, :anonymous_comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
		record.errors.add attr, 'not allowed' if value == true
	end
	
	validates_each :comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
		record.errors.add attr, 'not allowed' if value == false
	end
end