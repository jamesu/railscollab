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

require 'icalendar'

class FeedController < ApplicationController

  before_filter :token_login_required
  after_filter  :user_track
  
  def recent_activities
  	@activity_log = ApplicationLog.logs_for(@logged_user.projects, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
  	@activity_url = (url_for {}) + @logged_user.recent_activity_feed_url(nil)

  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = "Recent Activities"
  			
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
  			
  			render :text => ical.to_ical
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
  	@activity_url = (url_for {}) + @logged_user.recent_activity_feed_url(@project)

  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = "Recent Activities"
  			
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
  			
  			render :text => ical.to_ical
  		end
  	end
  end
  
  def recent_milestones
  	@milestones = ProjectMilestone.all_by_user(@logged_user)
  	@milestones_url = (url_for {}) + @logged_user.milestone_feed_url(nil)
  			
  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @milestones.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = "Recent milestones"
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
  			render :text => ical.to_ical
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
  	
  	@milestones = @project.open_milestones
  	@milestones_url = (url_for {}) + @logged_user.milestone_feed_url(@project)
		    
  	respond_to do |format|
  		format.html do
  			render :text => '404 Not found', :status => 404
  		end
  		
  		format.rss do
  			render :text => '404 Not found', :status => 404 unless @milestones.length > 0
  		end
  		
  		format.ics do
  			ical = Icalendar::Calendar.new
  			ical.properties['X-WR-CALNAME'] = "#{@project.name} milestones"
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
  			render :text => ical.to_ical
  		end
  	end
  end
  
end
