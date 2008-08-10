=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

module AdministrationHelper
    def administration_tabbed_navigation(current)
	  items = [{:id => :index, :url => '/administration/index'},
	           {:id => :company, :url => '/administration/company'},
	           {:id => :members, :url => '/administration/members'},
	           {:id => :clients, :url => '/administration/clients'},
	           {:id => :projects, :url => '/administration/projects'},
	           {:id => :configuration, :url => '/administration/configuration'},
	           {:id => :tools, :url => '/administration/tools'}]
	           #{:id => :upgrade, :url => '/administration/upgrade'}]
	  
	  @selected_navigation_item = current
	  return items
    end
  
    def administration_crumbs(current, extras=[])
	  [{:title => :dashboard, :url => '/dashboard'},
	   {:title => :administration, :url => '/administration'}] + extras + [{:title => current}]
    end              
end
