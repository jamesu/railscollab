#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

class DashboardController < ApplicationController
  after_filter  :user_track
  helper :dashboard

  def index
    when_fragment_expired "user#{@logged_user.id}_dblog", Time.now.utc + (60 * Rails.configuration.minutes_to_activity_log_expire) do
      if @active_projects.length > 0
        include_private = @logged_user.member_of_owner?

        project_ids = @active_projects.collect{ |project| project.id }

        activity_conditions = include_private ?
          { :project_id => project_ids } :
          { :project_id => project_ids, :is_private => false }

        @activity_log = ApplicationLog.all(:conditions => activity_conditions, :order => 'created_on DESC, id DESC', :limit => Rails.configuration.project_logs_per_page)
      else
        @activity_log = []
      end
    end

    @time_now = Time.zone.now
    @late_milestones = ProjectMilestone.all_assigned_to(@logged_user,
                                                        nil,
                                                        nil,
                                                        (@time_now - 1.day).utc.to_date,
                                                        nil,
                                                        true)
    @upcoming_milestones = ProjectMilestone.all_assigned_to(@logged_user,
                                                            nil,
                                                            @time_now.utc.to_date,
                                                            (@time_now.utc + 14.days).to_date,
                                                            nil,
                                                            true)
    
    @calendar_milestones = @upcoming_milestones.group_by do |obj|
      date = obj.due_date.to_date
      "#{date.month}-#{date.day}"
    end

    @online_users = User.get_online
    @my_projects = @active_projects
    @content_for_sidebar = 'index_sidebar'
  end

  def my_projects
    # Create the sorted projects list
    sort_type = params[:orderBy]
    sort_type = 'priority' unless ['name'].include?(params[:orderBy])
    @sorted_projects = @active_projects.sort_by do |item|
      item[sort_type].nil? ? 0 : item[sort_type]
    end

    @finished_projects = @logged_user.finished_projects
    @content_for_sidebar = 'my_projects_sidebar'
  end

  def my_tasks
    @has_assigned_tasks = nil
    @projects_milestonestasks = @active_projects.collect do |project|
    @has_assigned_tasks ||= true unless (project.milestones_by_user(@logged_user).empty? and 
                                         project.tasks_by_user(@logged_user).empty?)

      {
        :name       => project.name,
        :id         => project.id,
        :milestones => project.milestones_by_user(@logged_user),
        :tasks      => project.tasks_by_user(@logged_user)
      }
    end
    @has_assigned_tasks ||= false

    @content_for_sidebar = 'my_tasks_sidebar'
  end

  def milestones
    @time_now = Time.zone.now
    
    @date_start = @time_now.utc.to_date.beginning_of_month
    @date_end = @date_start + 3.months - 1.day
    
    assignee = unless params[:assigned_to].nil? or params[:assigned_to].empty?
      if params[:assigned_to][0] == 99 # c
        Company.find(params[:assigned_to][1...(params[:assigned_to].length)].to_i)
      else
        User.find(params[:assigned_to])
      end
    else
      nil
    end
    
    @late_milestones = ProjectMilestone.all_assigned_to(@logged_user,
                                                        assignee,
                                                        nil,
                                                        @date_start-1,
                                                        nil,
                                                        true)

    @milestones = ProjectMilestone.all_assigned_to(@logged_user, 
                                                   assignee,
                                                   @date_start, 
                                                   @date_end, nil, true).group_by do |obj| 
      date = obj.due_date.to_date
      "#{date.month}-#{date.day}"
    end
  end

  def search
    @current_search = params[:search_id]

    unless @current_search.nil?
      @last_search = @current_search

      current_page = params[:page].to_i
      current_page = 1 unless current_page > 0

      @search_results, @total_search_results = Project.search_for_user(@last_search, @logged_user, {:page => current_page, :per_page => Rails.configuration.search_results_per_page})

      @tag_names = []
      @pagination = []
      @start_search_results = Rails.configuration.search_results_per_page * (current_page-1)
      (@total_search_results.to_f / Rails.configuration.search_results_per_page).ceil.times {|page| @pagination << page+1}
    else
      @last_search = :search_box_default.l
      @search_results = []

      @tag_names = []
    end

    @content_for_sidebar = 'projects/search_sidebar'
  end
end
