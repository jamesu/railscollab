=begin
RailsCollab
-----------
Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

module AdministrationHelper
  def administration_tabbed_navigation(current=0)
	 items = [{:id => 0, :title => 'Index', :url => '/administration/index', :selected => false},
		{:id => 1, :title => 'Company', :url => '/administration/company', :selected => false},
		{:id => 2, :title => 'Members', :url => '/administration/members', :selected => false},
		{:id => 3, :title => 'Clients', :url => '/administration/clients', :selected => false},
		{:id => 4, :title => 'Projects', :url => '/administration/projects', :selected => false},
		{:id => 5, :title => 'Configuration', :url => '/administration/configuration', :selected => false},
		{:id => 6, :title => 'Tools', :url => '/administration/tools', :selected => false},
		{:id => 7, :title => 'Upgrade', :url => '/administration/upgrade', :selected => false}]
		
		items[current][:selected] = true
		return items
  end
  
  def administration_crumbs(current, extras=[])
    [{:title => 'Dashboard', :url => '/dashboard'},
	  {:title => 'Administration', :url => '/administration'}] + extras + [{:title => current}]
  end              
end
