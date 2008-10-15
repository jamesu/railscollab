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

module ProjectHelper
  include AdministrationHelper

  def project_tabbed_navigation(current)
    project_id = @active_project.id
    items = [{:id => :overview,   :url => "/project/#{project_id}/overview"}]
    items << {:id => :messages,   :url => "/project/#{project_id}/message"}
    items << {:id => :tasks,      :url => "/project/#{project_id}/task_lists"}
    items << {:id => :milestones, :url => "/project/#{project_id}/milestone"}
    items << {:id => :time,       :url => "/project/#{project_id}/time"} if @logged_user.has_permission(@active_project, :can_manage_time)
    items << {:id => :files,      :url => "/project/#{project_id}/files"}
    items << {:id => :forms,      :url => "/project/#{project_id}/form"} if @logged_user.is_admin?
    items << {:id => :people,     :url => "/project/#{project_id}/people"}

    @selected_navigation_item = current
    items
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
end
