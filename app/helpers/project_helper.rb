#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

module ProjectHelper
  include AdministrationHelper

  def project_tabbed_navigation
    project_id = @active_project.id
    items = [{:id => :overview,   :url => "/project/#{project_id}/overview"}]
    items << {:id => :messages,   :url => "/project/#{project_id}/message"}
    items << {:id => :tasks,      :url => "/project/#{project_id}/task_lists"}
    items << {:id => :milestones, :url => "/project/#{project_id}/milestone"}
    items << {:id => :ptime,      :url => "/project/#{project_id}/time"} if @logged_user.has_permission(@active_project, :can_manage_time)
    items << {:id => :files,      :url => "/project/#{project_id}/files"}
    items << {:id => :wiki,       :url => "/project/#{project_id}/wiki_pages"}
    items << {:id => :people,     :url => "/project/#{project_id}/people"}

    items
  end

  def current_tab
    case action_name
      when 'people' then :people
      when 'add', 'edit', 'permissions' then :projects
      else :overview
    end
  end

  def project_crumbs(current, extras=[])
    [{:title => :dashboard,           :url => '/dashboard'},
     {:title => @active_project.name, :url => "/project/#{@active_project.id}/overview"}] + extras  << {:title => current}
  end

  def assign_select_options(project)
    permissions = @logged_user.permissions_for(project)
    return [] if permissions.nil? or !(permissions.can_assign_to_owners or permissions.can_assign_to_other)

    items = permissions.can_assign_to_other ? [['Anyone', 0]] : []
    project.companies.each do |company|
      next if company.is_owner? and !permissions.can_assign_to_owners
      next if !company.is_owner? and !permissions.can_assign_to_other

      items += [['--'], [company.name, "c#{company.id}"]]
      items += company.users.collect do |user|
        if user.member_of(project)
          ["#{company.name}: #{user.username}", user.id.to_s]
        else
          nil
        end
      end.compact()
    end

    items
  end
  
  def select_file_options(project, current_object=nil)
    file_ids = current_object.nil? ? [] : current_object.project_file_ids
    
    conds = {'project_id' => project.id, 'is_visible' => true}
    conds['is_private'] = false unless @logged_user.member_of_owner?

    [['-- None --', 0]] + ProjectFile.all(:conditions => conds, :select => 'id, filename').collect do |file|
      if file_ids.include?(file.id)
        nil
      else
        [file.filename, file.id]
      end
    end.compact
  end
  
  def select_milestone_options(project)
    conds = {'project_id' => project.id}
    conds['is_private'] = false unless @logged_user.member_of_owner?
    
    [['-- None --', 0]] + ProjectMilestone.all(:conditions => conds).collect do |milestone|
      [milestone.name, milestone.id]
    end
  end

  def select_message_options(project)
    conds = {'project_id' => project.id}
    conds['is_private'] = false unless @logged_user.member_of_owner?
    
    ProjectMessage.all(:conditions => conds, :select => 'id, title').collect do |message|
      [message.title, message.id]
    end
  end
end
