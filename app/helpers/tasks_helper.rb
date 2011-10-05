#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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

module TasksHelper
  def current_tab
    :tasks
  end

  def current_crumb
    case action_name
      when 'new', 'create' then :add_task
      when 'edit', 'update' then :edit_task
      when 'show' then truncate(@task.text, :length => 25)
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :tasks, :url => task_lists_path}
    unless @task_list.nil?
      crumbs << {:title => @task_list.name, :url => task_list_path(:id => @task_list.id)}
    else
      crumbs << {:title => @logged_user.display_name, :url => "/dashboard/my_tasks"}
    end
    crumbs
  end

  def additional_stylesheets
    ['project/task_list', 'project/task', 'project/comments'] if action_name == 'show'
  end
end
