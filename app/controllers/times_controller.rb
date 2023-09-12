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

class TimesController < ApplicationController

  layout 'project_website'
  

  
  
  before_action :prepare_times,   :only   => [:index, :by_task, :export]
  after_action  :user_track,      :only   => [:index, :by_task, :view]

  def index
    authorize! :manage_time, @active_project
    
    respond_to do |format|
      format.html {
        @project = @active_project
        @content_for_sidebar = 'index_sidebar'
    
        @times = @project.time_records.where(@time_conditions)
                                       .page(@current_page).per(Rails.configuration.railscollab.times_per_page)
                                       .order("#{@sort_type} #{@sort_order}")
        
        @pagination = []
        @times.total_pages.times {|page| @pagination << page+1}
    
      }
      format.xml  {
        @times = @project.time_records.where(@time_conditions)
                                       .offset(params[:offset])
                                       .limit(params[:limit] || Rails.configuration.railscollab.times_per_page) 
                                       .order("#{@sort_type} #{@sort_order}")
        
        render xml: @times.to_xml(root: 'times')
      }
    end
  end

  def by_task
    authorize! :manage_time, @active_project

    respond_to do |format|
      format.html {
        @tasks = TimeRecord.find_by_task_lists(@active_project.task_lists, @time_conditions)
        @content_for_sidebar = 'index_sidebar'
      }
    end
  end

  def show
    authorize! :show, @time
  end

  def new
    authorize! :create_time, @active_project

    @time = @active_project.time_records.build
    @open_task_lists = @active_project.task_lists.is_open
    @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
    @task_filter = Proc.new {|task| task.is_completed? }
  end
  
  def create
    authorize! :create_time, @active_project

    @time = @active_project.time_records.build
    
    @time.attributes = time_params
    @time.start_date = Time.current unless @time.done_date
    @time.created_by = @logged_user
    
    respond_to do |format|
      if @time.save
        add_running_time(@time)
        
        format.html {
          error_status(false, :success_added_time)
          redirect_back_or_default(@time.object_url)
        }
        format.js   { respond_with_time(@time) }
        format.xml  { render xml: @time.to_xml(root: 'time'), status: :created, location: @time }
      else
        @open_task_lists = @active_project.task_lists.is_open
        @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
        @task_filter = Proc.new {|task| task.is_completed? }
        format.html { render action: "new" }
        format.js   { respond_with_time(@time) }
        format.xml  { render xml: @time.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :edit, @time

    @open_task_lists = @active_project.task_lists.is_open
    @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
    @open_task_lists << @time.task_list unless @time.task_list.nil? || @open_task_lists.include?(@time.task_list)
    @task_filter = Proc.new {|task| task.is_completed? && task != @time.task}
  end

  def update
    authorize! :edit, @time

    @time.attributes = time_params
    @time.updated_by = @logged_user
    
    respond_to do |format|
      if @time.save
        format.html {
          error_status(false, :success_edited_time)
          redirect_back_or_default(@time.object_url)
        }
        format.xml  { head :ok }
      else
        @open_task_lists = @active_project.task_lists.is_open
        @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
        @open_task_lists << @time.task_list unless @time.task_list.nil? || @open_task_lists.include?(@time.task_list)
        @task_filter = Proc.new {|task| task.is_completed? && task != @time.task}
        format.html { render action: "edit" }
        format.xml  { render xml: @time.errors, status: :unprocessable_entity }
      end
    end
  end

  def stop
    authorize! :edit, @time
    
    @time.hours = @time.hours # Save calculated hours before setting done_date
    @time.done_date = Time.current
    @time.updated_by = @logged_user
    @time.save
    
    remove_running_time(@time)
    
    respond_to do |format|
      format.html {
        error_status(false, :success_stopped_time)
        redirect_back_or_default(@time.object_url)
      }
      format.js { respond_with_time(@time) }
      format.xml  { head :ok }
    end
    
  end

  def destroy
    authorize! :delete, @time
    
    remove_running_time(@time)
    
    @time.updated_by = @logged_user
    @time.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_time)
        redirect_back_or_default(times_url)
      }
      format.js { respond_with_time(@time) }
      format.xml  { head :ok }
    end
  end

private

  def current_tab
    :ptime
  end

  def current_crumb
    case action_name
      when 'index', 'by_task' then :ptime
      when 'new', 'create' then :add_time
      when 'edit', 'update' then :edit_time
      when 'show' then @time.name
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {title: :ptime, url: times_url} unless ['index', 'by_task'].include? action_name
    crumbs
  end

  def time_params
    params[:time].nil? ? {} : params[:time].permit(:name, :description, :done_date, :hours, :open_task_id, :assigned_to_id, :is_private, :is_billable)
  end

  def respond_with_time(time)
    if time.errors
      render json: {id: time.id, time: time, task: time.task, content: render_to_string({partial: 'listed', collection: [time]})}
    else
      render json: {id: time.id, time: time, task: time.task, errors: time.errors}, status: :unprocessable_entity
    end
  end

  def load_related_object
    begin
      @time = @active_project.time_records.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_time, {}, false)
      redirect_back_or_default project_times_path(@active_project)
      return false
    end

    true
  end

  def prepare_times
    @current_page = params[:page].to_i
    @current_page = 1 unless @current_page > 0
    
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
