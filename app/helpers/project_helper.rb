=begin
RailsCollab
-----------

Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)

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
    include ActionView::Helpers::AdministrationHelper
    
	def project_tabbed_navigation(current=0)
	
	 act_proj="#{@active_project.id}"
	 items = [{:id => 0, :title => 'Overview', :url => "/project/#{act_proj}/overview", :selected => false},
	 {:id => 1, :title => 'Messages', :url => "/project/#{act_proj}/message", :selected => false},
	 {:id => 2, :title => 'Tasks', :url => "/project/#{act_proj}/task", :selected => false},
	 {:id => 3, :title => 'Milestones', :url => "/project/#{act_proj}/milestone", :selected => false},
	 {:id => 4, :title => 'Time', :url => "/project/#{act_proj}/time", :selected => false},
	 {:id => 5, :title => 'Files', :url => "/project/#{act_proj}/files", :selected => false},
	 {:id => 6, :title => 'Tags', :url => "/project/#{act_proj}/tags", :selected => false},
	 {:id => 7, :title => 'Forms', :url => "/project/#{act_proj}/form", :selected => false},
	 {:id => 8, :title => 'People', :url => "/project/#{act_proj}/people", :selected => false}]
	
     items[current][:selected] = true
	 return items
	end
	
	def project_crumbs(current="Index", extras=[])
	 [{:title => 'Dashboard', :url => '/dashboard'},
	  {:title => (html_escape @active_project.name), :url => "/project/#{@active_project.id}/overview"}] + extras  << {:title => current}
	end

	def assign_select_options(project)
	   items = []
	   
	   permissions = @logged_user.permissions_for(project)
	   return items if (permissions.nil? or !(permissions.can_assign_to_owners or permissions.can_assign_to_other))
	   
	   project.companies.each do |company|
	   	 next if (company.is_owner?) and !permissions.can_assign_to_owners
	   	 next if (!company.is_owner?) and !permissions.can_assign_to_other
	   	 
	     items += [["--"], [company.name, "c#{company.id}"]]
	     items += company.users.collect do |user|
	       if user.member_of(project)
	         ["#{company.name}: #{user.username}", user.id.to_s]
	       else
	         nil
	       end
	     end.compact()
	   end
	   
	   if permissions.can_assign_to_other
	   	 [["Anyone", 0]] + items
	   else
	   	 items
	   end
	end
end
