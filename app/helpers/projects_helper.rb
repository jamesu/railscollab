#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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

module ProjectsHelper
  def current_tab
    case action_name
      when 'people', 'permissions' then :people
      when 'new', 'create', 'edit', 'update', 'index' then :projects
      else :overview
    end
  end

  def current_crumb
    case action_name
      when 'new', 'create' then :add_project
      when 'edit', 'update' then :edit_project
      when 'search' then :search_results
      when 'show' then :overview
      else super
    end
  end

  def extra_crumbs
    case action_name
      when 'new', 'create', 'edit', 'update', 'permissions' then [{:title => :projects, :url => "/administration/projects"}]
      else super
    end
  end

  def page_title
    case action_name
      when 'show' then I18n.t('overview')
      when 'index' then I18n.t('projects')
      else super
    end
  end

  def additional_stylesheets
    case action_name
      when 'permissions' then ['project/permissions']
      when 'people' then ['project/people']
      when 'search' then ['project/search_results']
      when 'show' then ['project/project_log', 'application_logs']
    end
  end
end
