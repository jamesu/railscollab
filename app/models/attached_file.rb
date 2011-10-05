#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
# Portions Copyright (C) René Scheibe
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class AttachedFile < ActiveRecord::Base
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	
	belongs_to :project_file, :foreign_key => 'file_id'
	belongs_to :rel_object, :polymorphic => true, :counter_cache => true
	
	def self.clear_attachment(object, attach_id)
	  conds = ['rel_object_type = ? AND rel_object_id = ? AND file_id = ?', 
             object.class.to_s, 
             object.id, 
             attach_id]
	                                          
	  AttachedFile.where(conds).each do |attach|
	    if !attach.project_file.nil? and !attach.project_file.is_visible and attach.project_file.attached_files.length <= 1
	      attach.project_file.destroy
	    end
	  end
	  
	  AttachedFile.delete_all(conds)
	end
	
	def self.clear_attachments(object)
	  conds = ['rel_object_type = ? AND rel_object_id = ?', 
             object.class.to_s, 
             object.id]
	                                 
	  AttachedFile.where(conds).each do |attach|
	    if !attach.project_file.nil? and !attach.project_file.is_visible and attach.project_file.attached_files.length <= 1
	      AttachedFile.delete_all(['rel_object_type = ? AND rel_object_id = ? AND file_id = ?', 
               object.class.to_s, 
               object.id, attach.file_id])
      end
	  end
	end
	
	def self.clear_files(file_id)
		AttachedFile.delete_all(['file_id = ?', file_id])
	end
end
