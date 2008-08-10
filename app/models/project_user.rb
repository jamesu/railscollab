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

class ProjectUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :project
	
	before_create :ensure_permissions
	
	# Update these when required
	@@permission_fields = [
	         :can_manage_messages,
	         :can_manage_tasks,
	         :can_manage_milestones,
	         :can_manage_time,
	         :can_upload_files,
	         :can_manage_files,
	         :can_assign_to_owners,
	         :can_assign_to_other
	]
	
	def ensure_permissions(set_val=true)
	  @@permission_fields.each do |field| 
	  	self[field] ||= set_val
	  end
	end
	
	def self.update_str(vals={}, user=nil)
	 member_of_owner = !user.nil? ?  user.member_of_owner? : false
	 
	 mvals = {}
	 @@permission_fields.each do |field|
	   mvals[field] = member_of_owner
	 end
	 
	 # Override mvals with vals if we are not a member of the owner
	 unless member_of_owner
		vals.each do |val|
			intern_val = val.intern
			mvals[intern_val] = true if !mvals[intern_val].nil?
		end
	 end
	 
	 return [(mvals.keys.collect { |key| "#{key} = ?" }.join ', ')] + mvals.keys.collect { |key| mvals[key] }
	end
	
	def reset_permissions
	  @@permission_fields.each do |field| 
	  	self[field] = false
	  end
    end
	
	def has_all_permissions?
	  @@permission_fields.each do |field| 
	  	return false if !self[field]
	  end
	  
	  return true
	end
	
	def self.permission_names()
	  vals = {}
	  
	  @@permission_fields.each do |field| 
	  	vals[field] = field.l
	  end
	  
	  return vals
	end
	
	def self.check_permission(user, project, permission)
	 return ProjectUser.find(:first, :conditions => "project_id = #{project.id} AND user_id = #{user.id} AND #{permission} = 1", :select => [:user_id, :username])
	end
end
