#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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

require 'icalendar'
require 'csv'

class FeedController < ApplicationController

  after_filter :user_track

  def recent_activities
  	@activity_log = Activity.logs_for(@logged_user.projects, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
  	@activity_url = root_url

  	respond_to do |format|
      format.html do
        render :text => '404 Not found', :status => 404
      end

      format.rss do
        render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
      end

      format.ics do
        ical = Icalendar::Calendar.new
        ical.properties['X-WR-CALNAME'] = I18n.t('recent_activities')

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

  	unless @logged_user.member_of(@project)
      render :text => '404 Not found', :status => 404
      return
  	end

  	@activity_log = Activity.logs_for(@project, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
  	@activity_url = project_url(@project)

  	respond_to do |format|
      format.html do
        render :text => '404 Not found', :status => 404
      end

      format.rss do
        render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
      end

      format.ics do
        ical = Icalendar::Calendar.new
        ical.properties['X-WR-CALNAME'] = I18n.t('recent_activities')

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
  	@milestones = Milestone.all_by_user(@logged_user)
  	@milestones_url = url_for(:controller => 'dashboard', :action => 'milestones')

  	respond_to do |format|
      format.html do
        render :text => '404 Not found', :status => 404
      end

      format.rss do
        render :text => '404 Not found', :status => 404 unless @milestones.length > 0
      end

      format.ics do
        ical = Icalendar::Calendar.new
        ical.properties['X-WR-CALNAME'] = I18n.t('recent_milestones')
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

  def milestones
  	begin
      @project = Project.find(params[:project])
  	rescue ActiveRecord::RecordNotFound
      render :text => 'Not found', :status => 404
      return
  	end

  	unless @logged_user.member_of(@project)
      render :text => 'Not found', :status => 404
      return
  	end

    @milestones = @project.milestones.is_open
    @milestones = @milestones.is_public unless @logged_user.member_of_owner? 
    @milestones_url = milestones_url(@project)

  	respond_to do |format|
      format.html do
        render :text => '404 Not found', :status => 404
      end

      format.rss do
        render :text => '404 Not found', :status => 404 unless @milestones.length > 0
      end

      format.ics do
        ical = Icalendar::Calendar.new
        ical.properties['X-WR-CALNAME'] = "#{@project.name} #{I18n.t('milestones')}"
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

      @times = @logged_user.member_of_owner? ? @project.time_records : @project.time_records.is_public
    else
      @times = TimeRecord.all_by_user(@logged_user).where('done_date IS NOT NULL')
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
        build_str = CSV.generate do |csv|
        csv << ['Project', 'Date (UTC)', 'Attributed to', 'Hours', 'Name', 'Description', 'Task list', 'Task']
        @times.each { |time| csv << [time.project.name,
              time.running? ? '' : time.done_date.strftime('%m/%d/%Y'),
              time.assigned_to.nil? ? 'Anyone' : time.assigned_to.display_name,
              time.hours,
              time.name,
              time.description,
              time.task_list.nil? ? '' : time.task_list.object_name,
              time.task.nil? ? '' : time.task.object_name,
            ] }
        end
        render :text => build_str, :content_type => 'application/vnd.ms-excel'
      end
    end
  end

  protected

  def protect_token?(action)
    action != 'export_times'
  end
end
