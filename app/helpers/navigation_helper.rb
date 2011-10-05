#==
# RailsCollab
# Copyright (C) 2009 Sergio Cambra
# Portions Copyright (C) 2011 James S Urquhart
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
    title = I18n.t(title) if title.is_a? Symbol
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
      {:id => :people,        :url => companies_path},
      {:id => :projects,      :url => projects_path}
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
    items = [{:id => :overview,   :url => project_path(@active_project)}]
    items << {:id => :messages,   :url => messages_path(@active_project)}
    items << {:id => :tasks,      :url => task_lists_path(@active_project)}
    items << {:id => :milestones, :url => milestones_path(@active_project)}
    items << {:id => :ptime,      :url => times_path(@active_project)} if @logged_user.has_permission(@active_project, :can_manage_time)
    items << {:id => :files,      :url => files_path(@active_project)}
    items << {:id => :wiki,       :url => wiki_pages_path(@active_project)}
    items << {:id => :people,     :url => people_project_path(@active_project)}

    items
  end

  def project_crumbs(current=nil, extras=[])
    [
      {:title => :dashboard,           :url => '/dashboard'},
      {:title => @active_project.name, :url => project_path(:id => @active_project.id)}
    ] + extra_crumbs + [{:title => current_crumb}]
  end
end
