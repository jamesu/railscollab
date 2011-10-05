#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

class TasksController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  before_filter :grab_list, :except => [:create, :new]
  before_filter :grab_list_required, :only => [:index, :create, :new]
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /tasks
  # GET /tasks.xml
  def index
    respond_to do |format|
      format.html {
        @open_task_lists = @active_project.task_lists.is_open
        @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
        @completed_task_lists = @active_project.task_lists.completed
        @completed_task_lists = @completed_task_lists.is_public unless @logged_user.member_of_owner?
        @content_for_sidebar = 'task_lists/index_sidebar'
      }
      format.xml  {
        @tasks = @task_list.tasks
        render :xml => @tasks.to_xml(:root => 'tasks')
      }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    begin
      @task = (@task_list||@active_project).tasks.find(params[:id])
      @task_list ||= @task.task_list
    rescue
      return error_status(true, :invalid_task)
    end
    
    respond_to do |format|
      format.html { }
      format.js { respond_with_task(@task) }
      format.xml  { render :xml => @task.to_xml(:root => 'task') }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    authorize! :create_task, @task_list
    
    @task = @task_list.tasks.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task.to_xml(:root => 'task') }
    end
  end

  # GET /tasks/1/edit
  def edit
    begin
      @task = @task_list.tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
    
    authorize! :edit, @task
    
    respond_to do |f|
      f.html
      f.js { respond_with_task(@task, 'ajax_form') }
    end
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    authorize! :create_task, @task_list
    
    @task = @task_list.tasks.build(params[:task])
    @task.created_by = @logged_user
    
    respond_to do |format|
      if @task.save
        Notifier.deliver_task(@task.user, @task) if params[:send_notification] and @task.user
        flash[:notice] = 'ListItem was successfully created.'
        format.html { redirect_back_or_default(task_lists_path) }
        format.js { respond_with_task(@task) }
        format.xml  { render :xml => @task.to_xml(:root => 'task'), :status => :created, :location => @task }
      else
        format.html { render :action => "new" }
        format.js { respond_with_task(@task) }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    begin
      @task = @task_list.tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
    
    authorize! :edit, @task
    
    @task.updated_by = @logged_user

    respond_to do |format|
      if @task.update_attributes(params[:task])
        Notifier.deliver_task(@task.user, @task) if params[:send_notification] and @task.user
        flash[:notice] = 'ListItem was successfully updated.'
        format.html { redirect_back_or_default(task_lists_path) }
        format.js { respond_with_task(@task) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js { respond_with_task(@task) }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    begin
      @task = @task_list.tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
    
    authorize! :delete, @task
    
    @task.updated_by = @logged_user
    @task.destroy

    respond_to do |format|
      format.html { redirect_back_or_default(task_lists_url) }
      format.js { render :json => { :id => @task.id } }
      format.xml  { head :ok }
    end
  end

  # PUT /tasks/1/status
  # PUT /tasks/1/status.xml
  def status
    begin
      @task = @task_list.tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
    
    authorize! :complete, @task
    
    @task.set_completed(params[:task][:completed] == 'true', @logged_user)
    @task.order = @task_list.tasks.length
    @task.save

    respond_to do |format|
      format.html { redirect_back_or_default(task_lists_url) }
      format.js { respond_with_task(@task) }
      format.xml  { head :ok }
    end

  end

protected

  def respond_with_task(task, partial='show')
    task_class = task.is_completed? ? 'completedTasks' : 'openTasks'
    if task.errors
      render :json => {:task_class => task_class, :id => task.id, :content => render_to_string({:partial => partial, :collection => [task]})}
    else
      render :json => {:task_class => task_class, :id => task.id, :errors => task.errors}, :status => :unprocessable_entity
    end
  end
  
  def grab_list_required
    if params[:task_list_id].nil?
      error_status(true, :invalid_task)
      return false
    end
    grab_list
  end

  def grab_list
    return if params[:task_list_id].nil?
    begin
      @task_list = @active_project.task_lists.find(params[:task_list_id])
      authorize! :show, @task_list
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_task)
      return false
    end
    
    true
  end
end
