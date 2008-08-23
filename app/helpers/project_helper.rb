=begin
RailsCollab
-----------

Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)

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
	include AdministrationHelper
	
	def project_tabbed_navigation(current)
	  act_proj="#{@active_project.id}"
	  items = [{:id => :overview, :url => "/project/#{act_proj}/overview"}]
	  
	  items << {:id => :messages, :url => "/project/#{act_proj}/message"} if true
	  items << {:id => :tasks, :url => "/project/#{act_proj}/task"} if true
	  items << {:id => :milestones, :url => "/project/#{act_proj}/milestone"} if true
	  items << {:id => :time, :url => "/project/#{act_proj}/time"} if @logged_user.has_permission(@active_project, :can_manage_time)
	  items << {:id => :files, :url => "/project/#{act_proj}/files"} if true
	  items << {:id => :forms, :url => "/project/#{act_proj}/form"} if @logged_user.is_admin?
	  items << {:id => :people, :url => "/project/#{act_proj}/people"} if true
	  
	  @selected_navigation_item = current
	  return items
	end
	
	def project_crumbs(current, extras=[])
	  [{:title => :dashboard, :url => '/dashboard'},
	   {:title => @active_project.name, :url => "/project/#{@active_project.id}/overview"}] + extras  << {:title => current}
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
