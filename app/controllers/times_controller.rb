#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

class TimesController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  before_filter :obtain_time,     :except => [:index, :by_task, :new, :create]
  before_filter :prepare_times,   :only   => [:index, :by_task, :export]
  after_filter  :user_track,      :only   => [:index, :by_task, :view]

  def index
    return error_status(true, :insufficient_permissions) unless @logged_user.has_permission(@active_project, :can_manage_time)
      
    unless @logged_user.has_permission(@active_project, :can_manage_time)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default @active_project
    end
    
    respond_to do |format|
      format.html {
        @project = @active_project
        @content_for_sidebar = 'index_sidebar'
    
        @times = @project.project_times.find(:all, 
                                             :conditions => @time_conditions, 
                                             :page => {:size => AppConfig.times_per_page, :current => @current_page}, 
                                             :order => "#{@sort_type} #{@sort_order}")
        
        @pagination = []
        @times.page_count.times {|page| @pagination << page+1}
    
      }
      format.xml  {
        @times = @project.project_times.find(:all, :conditions => @time_conditions,
                                                   :offset => params[:offset],
                                                   :limit => params[:limit] || AppConfig.times_per_page, 
                                                   :order => "#{@sort_type} #{@sort_order}")
        
        render :xml => @times.to_xml(:root => 'times')
      }
    end
  end

  def by_task
    return error_status(true, :insufficient_permissions) unless @logged_user.has_permission(@active_project, :can_manage_time)

    respond_to do |format|
      format.html {
        @tasks = ProjectTime.find_by_task_lists(@active_project.project_task_lists, @time_conditions)
        @content_for_sidebar = 'index_sidebar'
      }
    end
  end

  def show
    return error_status(true, :insufficient_permissions) unless @time.can_be_seen_by(@logged_user)
  end

  def new
    return error_status(true, :insufficient_permissions) unless (ProjectTime.can_be_created_by(@logged_user, @active_project))

    @time = @active_project.project_times.build
    @open_task_lists = @active_project.project_task_lists.open(@logged_user.member_of_owner?)
    @open_task_lists.each do |task_list|
      task_list.project_tasks.reject! {|task| task.is_completed?}
    end
  end
  
  def create
    return error_status(true, :insufficient_permissions) unless (ProjectTime.can_be_created_by(@logged_user, @active_project))

    @time = @active_project.project_times.build
    
    @time.attributes = params[:time]
    @time.start_date = Time.current unless @time.done_date
    @time.created_by = @logged_user
    
    respond_to do |format|
      if @time.save
        add_running_time(@time)
        
        format.html {
          error_status(false, :success_added_time)
          redirect_back_or_default(@time)
        }
        format.js {}
        format.xml  { render :xml => @time.to_xml(:root => 'time'), :status => :created, :location => @time }
      else
        @open_task_lists = @active_project.project_task_lists.open(@logged_user.member_of_owner?)
        @open_task_lists.each do |task_list|
          task_list.project_tasks.reject! {|task| task.is_completed?}
        end
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @time.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    return error_status(true, :insufficient_permissions) unless @time.can_be_edited_by(@logged_user)

    @open_task_lists = @active_project.project_task_lists.open(@logged_user.member_of_owner?)
    @open_task_lists << @time.project_task_list unless @time.project_task_list.nil? || @open_task_lists.include?(@time.project_task_list)
    @open_task_lists.each do |task_list|
      task_list.project_tasks.reject! {|task| task.is_completed? && task != @time.project_task }
    end
  end

  def update
    return error_status(true, :insufficient_permissions) unless @time.can_be_edited_by(@logged_user)

    @time.attributes = params[:time]
    @time.updated_by = @logged_user
    
    respond_to do |format|
      if @time.save
        format.html {
          error_status(false, :success_edited_time)
          redirect_back_or_default(@time)
        }
        format.js {}
        format.xml  { head :ok }
      else
        @open_task_lists = @active_project.project_task_lists.open(@logged_user.member_of_owner?)
        @open_task_lists << @time.project_task_list unless @time.project_task_list.nil? || @open_task_lists.include?(@time.project_task_list)
        @open_task_lists.each do |task_list|
          task_list.project_tasks.reject! {|task| task.is_completed? && task != @time.project_task }
        end
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @time.errors, :status => :unprocessable_entity }
      end
    end
  end

  def stop
    return error_status(true, :insufficient_permissions) unless @time.can_be_edited_by(@logged_user)
    
    @time.hours = @time.hours # Save calculated hours before setting done_date
    @time.done_date = Time.current
    @time.updated_by = @logged_user
    @time.save
    
    remove_running_time(@time)
    
    respond_to do |format|
      format.html {
        error_status(false, :success_stopped_time)
        redirect_back_or_default(@time)
      }
      format.js {}
      format.xml  { head :ok }
    end
    
  end

  def destroy
    return error_status(true, :insufficient_permissions) unless (@time.can_be_deleted_by(@logged_user))
    
    remove_running_time(@time)
    
    @time.updated_by = @logged_user
    @time.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_time)
        redirect_back_or_default(times_url)
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

private

  def obtain_time
    begin
      @time = @active_project.project_times.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_time)
      redirect_back_or_default times_path
      return false
    end

    true
  end

  def prepare_times
    @current_page = params[:page].to_i
    @current_page = 0 unless @current_page > 0
    
    @time_conditions = @logged_user.member_of_owner? ? {} : {'is_private' => false}
    @sort_type = params[:orderBy]
    @sort_type = 'created_on' unless ['done_date', 'hours'].include?(params[:orderBy])
    @sort_order = 'DESC'
  end
  
  def add_running_time(time)
    @running_times.each { |chk| return if chk.id == time.id }
    @running_times << time
  end
  
  def remove_running_time(time)
    @running_times.reject! { |chk| chk.id == time.id ? true : false }
  end
end
