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

class ProjectUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :project
	
	before_create :ensure_permissions
	
	def ensure_permissions(set_val=true)
	 self.can_manage_messages ||= set_val
	 self.can_manage_tasks ||= set_val
	 self.can_manage_milestones ||= set_val
	 self.can_manage_time ||= set_val
	 self.can_upload_files ||= set_val
	 self.can_manage_files ||= set_val
	 self.can_assign_to_owners ||= set_val
	 self.can_assign_to_other ||= set_val
	end
	
	def self.update_str(vals={}, user=nil)
	 member_of_owner = !user.nil? ?  user.member_of_owner? : false
	 
	 mvals = {:can_manage_messages => member_of_owner,
	         :can_manage_tasks => member_of_owner,
	         :can_manage_milestones => member_of_owner,
	         :can_manage_time => member_of_owner,
	         :can_upload_files => member_of_owner,
	         :can_manage_files => member_of_owner,
	         :can_assign_to_owners => member_of_owner,
	         :can_assign_to_other=> member_of_owner,
	 }
	 
	 # Override mvals with vals if we are not a member of the owner
	 unless member_of_owner
		vals.each do |val|
			intern_val = val.intern
			mvals[intern_val] = true if !mvals[intern_val].nil?
		end
	 end
	 
	 return (mvals.keys.collect do |key|
	   "#{key} = #{mvals[key]}"
	 end.join ', ')
	end
	
	def reset_permissions
	 self.can_manage_messages = false
	 self.can_manage_tasks = false
	 self.can_manage_milestones = false
	 self.can_manage_time = false
	 self.can_upload_files = false
	 self.can_manage_files = false
	 self.can_assign_to_owners = false
	 self.can_assign_to_other = false
    end
	
	def has_all_permissions?
		return (self.can_manage_messages and self.can_manage_tasks and self.can_manage_milestones and self.can_manage_time and self.can_upload_files and self.can_manage_files and self.can_assign_to_owners and self.can_assign_to_other)
	end
	
	def self.permission_names()
	 {:can_manage_messages => "Manage messages",
	         :can_manage_tasks => "Manage tasks",
	         :can_manage_milestones => "Manage milestones",
	         :can_manage_time => "Manage time",
	         :can_upload_files => "Upload files",
	         :can_manage_files => "Manage files",
	         :can_assign_to_owners => "Assign tasks to members of owner company",
	         :can_assign_to_other=> "Assign tasks to members of other clients",
	 }
	end
	
	def self.check_permission(user, project, permission)
	 return ProjectUser.find(:first, :conditions => "project_id = #{project.id} AND user_id = #{user.id} AND #{permission} = 1", :select => :user_id)
	end
end
