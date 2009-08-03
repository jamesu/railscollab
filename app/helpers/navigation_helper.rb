#==
# RailsCollab
# Copyright (C) 2009 Sergio Cambra
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

module NavigationHelper
  def page_title
    title = current_crumb
    title = title.l if title.is_a? Symbol
    title
  end

  def current_crumb
    action_name.to_sym
  end

  def extra_crumbs
    []
  end

  def page_actions
    @page_actions
  end

  def additional_stylesheets
  end

  def administration_tabbed_navigation
    items = [
      {:id => :index,         :url => administration_path},
      {:id => :people,       :url => companies_path},
      {:id => :projects,      :url => projects_path},
      {:id => :configuration, :url => configurations_path},
      {:id => :tools,         :url => tools_path},
      #{:id => :upgrade,       :url => '/administration/upgrade'}
    ]
  end

  def administration_crumbs
    [
      {:title => :dashboard,      :url => '/dashboard'},
      {:title => :administration, :url => '/administration'}
    ] + extra_crumbs + [{:title => current_crumb}]
  end

  def dashboard_tabbed_navigation
    items = [{:id => :overview,       :url => '/dashboard/index'},
             {:id => :my_projects,    :url => '/dashboard/my_projects'},
             {:id => :my_tasks,       :url => '/dashboard/my_tasks'},
             {:id => :milestones,     :url => '/dashboard/milestones'}]
  end

  def dashboard_crumbs
    [{:title => :dashboard, :url => '/dashboard'}, {:title => current_crumb}]
  end

  def project_tabbed_navigation
    project_id = @active_project.id
    items = [{:id => :overview,   :url => "/project/#{project_id}"}]
    items << {:id => :messages,   :url => "/project/#{project_id}/messages"}
    items << {:id => :tasks,      :url => "/project/#{project_id}/task_lists"}
    items << {:id => :milestones, :url => "/project/#{project_id}/milestones"}
    items << {:id => :ptime,      :url => "/project/#{project_id}/times"} if @logged_user.has_permission(@active_project, :can_manage_time)
    items << {:id => :files,      :url => "/project/#{project_id}/files"}
    items << {:id => :wiki,       :url => "/project/#{project_id}/wiki_pages"}
    items << {:id => :people,     :url => "/project/#{project_id}/people"}

    items
  end

  def project_crumbs(current=nil, extras=[])
    [
      {:title => :dashboard,           :url => '/dashboard'},
      {:title => @active_project.name, :url => project_path(:id => @active_project.id)}
    ] + extra_crumbs + [{:title => current_crumb}]
  end
end
