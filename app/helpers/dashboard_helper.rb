=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

module DashboardHelper
	def dashboard_tabbed_navigation(current)
	  items = [{:id => :overview, :url => '/dashboard/index'},
	           {:id => :my_projects, :url => '/dashboard/my_projects'},
	           {:id => :my_tasks, :url => '/dashboard/my_tasks'}]
	  
	  @selected_navigation_item = current
	  return items
	end
	
	def dashboard_crumbs(current)
	 [{:title => :dashboard, :url => '/dashboard'},
	  {:title => current}]
	end
		
	def new_account_steps(user)
	 [{:title => :new_account_step1.l,
	   :content => :new_account_step1_info.l_with_args(:url => '/company/edit'),
	   :del => Company.owner.updated?},
	  {:title => :new_account_step2.l,
	   :content => :new_account_step1_info.l_with_args(:url => "/user/add?company_id=#{user.company.id}"),
	   :del => (Company.owner.users.length > 1)},
	  {:title => :new_account_step3.l,
	   :content => :new_account_step3_info.l_with_args(:url => '/company/add_client'),
	   :del => (Company.owner.clients.length > 0)},
	  {:title => :new_account_step4.l,
	   :content => :new_account_step4_info.l_with_args(:url => '/project/add'),
	   :del => (Company.owner.projects.length > 0)}]
	end
end
