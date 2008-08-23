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

class DashboardController < ApplicationController
    
    after_filter  :user_track
    	
	def index
	    @active_projects = @logged_user.active_projects
		
		when_fragment_expired "user#{@logged_user.id}_dblog", Time.now.utc + (60 * AppConfig.minutes_to_activity_log_expire) do
			if @active_projects.length > 0
				include_private = @logged_user.member_of_owner?
				
				project_ids = @active_projects.collect do |i|
					i.id
				end.join','
				
				activity_conditions = include_private ? 
				                      ["project_id in (#{project_ids})"] :
				                      ["project_id in (#{project_ids}) AND is_private = ?", false]
			
				@activity_log = ApplicationLog.find(:all, :conditions => activity_conditions, :order => 'created_on DESC, id DESC', :limit => AppConfig.project_logs_per_page)
			else
				@activity_log = []
			end
		end
		
		@today_milestones = @logged_user.todays_milestones
		@late_milestones = @logged_user.late_milestones
		
		@online_users = User.get_online()
		@my_projects = @active_projects
		@content_for_sidebar = 'index_sidebar'
	end
	
	def my_projects
		@active_projects = @logged_user.active_projects
		
		# Create the sorted projects list
		sort_type = params[:orderBy]
		sort_type = 'priority' unless ['name'].include?(params[:orderBy])
		@sorted_projects = @active_projects.sort_by { |item|
			item[sort_type].nil? ? 0 : item[sort_type]
		}
		
		@finished_projects = @logged_user.finished_projects
		@content_for_sidebar = 'my_projects_sidebar'
	end
	
	def my_tasks
		@active_projects = @logged_user.active_projects
	    @has_assigned_tasks = nil
        @projects_milestonestasks = @active_projects.collect do |project|
          @has_assigned_tasks ||= true unless (project.milestones_by_user(@logged_user).length == 0 and  project.tasks_by_user(@logged_user).length == 0)
          {:name => project.name, :id => project.id, :milestones => project.milestones_by_user(@logged_user), :tasks => project.tasks_by_user(@logged_user)}
        end
        @has_assigned_tasks ||= false
        
		@content_for_sidebar = 'my_tasks_sidebar'
	end
end
