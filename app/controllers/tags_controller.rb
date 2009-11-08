#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

class TagsController < ApplicationController

  layout 'project_website'

  before_filter :process_session
  after_filter  :user_track
  
  def show
    tags_in_project
    
    respond_to do |format|
      format.html { }
      format.xml { render :xml => [].to_xml(:root => 'tags') }
    end
  end

private

  def tags_in_project
  	@tag_name = CGI.unescape(params[:id])
  	@active_project = Project.find(params[:project_id]) rescue nil
    return if !verify_project
  	
  	@tag_object_list = Tag.find_objects(@tag_name, @active_project, !@logged_user.member_of_owner?)

  	@tag_names = Tag.list_by_project(@active_project, !@logged_user.member_of_owner?, false)
  	@content_for_sidebar = 'projects/search_sidebar'

  	@tagged_objects_count = @tag_object_list.length
  	@tagged_objects = {
      :messages   => @tag_object_list.select { |obj| obj.class == ProjectMessage },
      :milestones => @tag_object_list.select { |obj| obj.class == ProjectMilestone },
      :task_lists => @tag_object_list.select { |obj| obj.class == ProjectTaskList },
      :files      => @tag_object_list.select { |obj| obj.class == ProjectFile },
  	}
  end
end
