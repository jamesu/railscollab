#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

module AdministrationHelper
  def administration_tabbed_navigation
    items = [{:id => :index,         :url => '/administration/index'},
	           {:id => :people,       :url => '/administration/people'},
	           {:id => :projects,      :url => '/administration/projects'},
	           {:id => :configuration, :url => '/administration/configuration'},
	           {:id => :tools,         :url => '/administration/tools'}]
	          #{:id => :upgrade,       :url => '/administration/upgrade'}]
  end

  def current_tab
    action_name.to_sym
  end

  def administration_crumbs(current, extras=[])
    [{:title => :dashboard,      :url => '/dashboard'},
	 {:title => :administration, :url => '/administration'}] + extras + [{:title => current}]
  end
end
