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

require 'icalendar'
require 'csv'

class FeedController < ApplicationController

  after_filter  :user_track
  
  def recent_activities
  	@activity_log = ApplicationLog.logs_for(@logged_user.projects, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
  	@activity_url = AppConfig.site_url + @logged_user.recent_activity_feed_url(nil)

  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = :recent_activities.l
  			
  			@activity_log.each do |activity|
  				activity_date = activity.created_on.to_date
  				ical.event do
  					dtstart activity_date
  					dtend activity_date
  					uid "#{activity.rel_object_type}-#{activity.rel_object_id}"
  					summary "#{activity.project.name} - #{activity.action} #{activity.object_name}"
  					description "#{activity.project.name} - #{activity.action} #{activity.object_name}"
  				end
  			end
  			
  			render :text => ical.to_ical, :content_type => 'text/calendar'
  		end
  	end
  end
  
  def project_activities
  	begin
  		@project = Project.find(params[:project])
  	rescue ActiveRecord::RecordNotFound
  		render :text => '404 Not found', :status => 404
  		return
  	end
  	
  	if not @logged_user.member_of(@project)
  		render :text => '404 Not found', :status => 404
  		return
  	end
  	
  	@activity_log = ApplicationLog.logs_for(@project, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
  	@activity_url = AppConfig.site_url + @logged_user.recent_activity_feed_url(@project)

  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = :recent_activities.l
  			
  			@activity_log.each do |activity|
  				activity_date = activity.created_on.to_date
  				ical.event do
  					dtstart activity_date
  					dtend activity_date
  					uid "#{activity.rel_object_type}-#{activity.rel_object_id}"
  					summary "#{activity.project.name} - #{activity.action} #{activity.object_name}"
  					description "#{activity.project.name} - #{activity.action} #{activity.object_name}"
  				end
  			end
  			
  			render :text => ical.to_ical, :content_type => 'text/calendar'
  		end
  	end
  end
  
  def recent_milestones
  	@milestones = ProjectMilestone.all_by_user(@logged_user)
  	@milestones_url = AppConfig.site_url + @logged_user.milestone_feed_url(nil)
  			
  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @milestones.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = :recent_milestones.l
  			# TODO: timezone
  			
  			@milestones.each do |milestone|
  				milestone_date = milestone.due_date.to_date
  				ical.event do
  					dtstart milestone_date
  					dtend milestone_date
  					uid milestone.id
  					summary "#{milestone.name} (#{milestone.project.name})"
  					description milestone.description
  				end
  			end
  			render :text => ical.to_ical, :content_type => 'text/calendar'
  		end
  	end
  end
  
  def project_milestones
  	begin
  		@project = Project.find(params[:project])
  	rescue ActiveRecord::RecordNotFound
  		render :text => 'Not found', :status => 404
  		return
  	end
  	
  	if not @logged_user.member_of(@project)
  		render :text => 'Not found', :status => 404
  		return
  	end
  	
  	@milestones = @project.project_milestones.open(@logged_user.member_of_owner?)
  	@milestones_url = AppConfig.site_url + @logged_user.milestone_feed_url(@project)
		    
  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @milestones.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = "#{@project.name} #{:milestones.l}"
  			# TODO: timezone
  			
  			@milestones.each do |milestone|
  				milestone_date = milestone.due_date.to_date
  				ical.event do
  					dtstart milestone_date
  					dtend milestone_date
  					uid milestone.id
  					summary milestone.name
  					description milestone.description
  				end
  			end
  			render :text => ical.to_ical, :content_type => 'text/calendar'
  		end
  	end
  end
  
  def export_times
    if params.has_key?(:project)
  	 begin
  	     @project = Project.find(params[:project])
  	 rescue ActiveRecord::RecordNotFound
  	     render :text => '404 Not found', :status => 404
  	     return
  	 end
  	 
  	 @times = @logged_user.member_of_owner? ? @project.project_times : @project.project_times.open
  	else
  	 @times = ProjectTime.all_by_user(@logged_user)
  	end

  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.ics do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.csv do
  		    build_str = ''
  		    CSV.generate_row(['Project', 'Date (UTC)', 'Attributed to', 'Hours', 'Name', 'Description', 'Task list', 'Task'], 8, build_str)
  		    @times.each { |time| CSV.generate_row([time.project.name,
  		                                           time.done_date.strftime("%m/%d/%Y"),
  		                                           time.assigned_to.nil? ? 'Anyone' : time.assigned_to.display_name,
  		                                           time.hours,
  		                                           time.name,
  		                                           time.description,
  		                                           time.project_task_list.nil? ? '' : time.project_task_list.object_name,
  		                                           time.project_task.nil? ? '' : time.project_task.object_name,
  		                                           ], 8, build_str) }
  		    
  		    render :text => build_str, :content_type => "application/vnd.ms-excel"
  		end
  	end
  end

protected

  def protect_token?(action)
    action != 'export_times'
  end
  
end
