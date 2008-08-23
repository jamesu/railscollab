=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class TagController < ApplicationController

  layout 'project_website'

  before_filter :process_session
  after_filter  :user_track
  
  def project
  	@tag_name = params[:id]
  	tag_object_list = Tag.find_objects(@tag_name, @active_project, !@logged_user.member_of_owner?)
  	
  	@tag_names = Tag.list_by_project(@active_project, !@logged_user.member_of_owner?, false)
  	@content_for_sidebar = 'project/search_sidebar'
  	
  	@tagged_objects_count = tag_object_list.length
  	@tagged_objects = {
  		:messages => tag_object_list.select { |obj| obj.class == ProjectMessage },
  		:milestones => tag_object_list.select { |obj| obj.class == ProjectMilestone },
  		:task_lists => tag_object_list.select { |obj| obj.class == ProjectTaskList },
  		:files => tag_object_list.select { |obj| obj.class == ProjectFile },
  	}
  end
  
end
