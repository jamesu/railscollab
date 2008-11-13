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

class AttachedFile < ActiveRecord::Base
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	
	belongs_to :project_file, :foreign_key => 'file_id'
	belongs_to :rel_object, :polymorphic => true, :counter_cache => true
	
	def self.clear_attachment(object, attach_id)
	  AttachedFile.find(:all, :conditions => ['rel_object_type = ? AND rel_object_id = ? AND file_id = ?', 
	                                          object.class.to_s, 
	                                          object.id, 
	                                          attach_id]).each do |attach|
	    attach.project_file.destroy if attach.project_file.attach.attached_files.length <= 1
	    attach.destroy
	  end
	end
	
	def self.clear_attachments(object)
	  AttachedFile.find(:all, :conditions => ['rel_object_type = ? AND rel_object_id = ?', 
	                                          object.class.to_s, 
	                                          object.id]).each do |attach|
	    attach.project_file.destroy if attach.project_file.attach.attached_files.length <= 1
	    attach.destroy
	  end
	end
	
	def self.clear_files(file_id)
		AttachedFile.delete_all(['file_id = ?', file_id])
	end
end
