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

module TaskListsHelper
  def current_tab
    :tasks
  end

  def current_crumb
    case action_name
      when 'index' then :tasks
      when 'new', 'create' then :add_task_list
      when 'edit', 'update' then :edit_task_list
      when 'show' then @task_list.name
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :tasks, :url => task_lists_path} unless action_name == 'index'
    crumbs
  end

  def additional_stylesheets
    ['project/task_list']
  end

  def page_actions
    @page_actions = []

    if action_name == 'index'
      if can?(:create_task_list, @active_project)
        @page_actions << {:title => :add_task_list, :url=> new_task_list_path, :ajax => true}
      end
    end

    @page_actions
  end
end
