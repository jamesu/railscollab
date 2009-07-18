#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

module FoldersHelper
  def page_title
    case action_name
      when 'files' then :folder_name.l_with_args(:folder => @current_folder.name)
      else super
    end
  end

  def current_tab
    :files
  end

  def current_crumb
    case action_name
      when 'show' then @folder.nil? ? :files : @folder.name
      when 'edit' then :edit_folder
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :files, :url => "/project/#{@active_project.id}/files"}
    crumbs << {:title => @folder.name, :url => @folder.object_url} unless @folder.nil?
    crumbs
  end

  def page_actions
    @page_actions = []
  
    if ProjectFile.can_be_created_by(@logged_user, @active_project)
      @page_actions << {:title => :add_file, :url => "/project/#{@active_project.id}/files/add_file"}
    end

    if ProjectFolder.can_be_created_by(@logged_user, @active_project)
      @page_actions << {:title => :add_folder, :url => new_folder_path}
    end
    
    @page_actions
  end

  def additional_stylesheets
    ['project/files']
  end
end
