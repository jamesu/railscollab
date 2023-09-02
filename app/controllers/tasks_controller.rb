#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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
  include ActionView::Helpers::TextHelper
  layout 'project_website'
  

  
  before_action :grab_list, :except => [:create, :new]
  before_action :grab_list_required, :only => [:index, :create, :new]
  after_action  :user_track, :only => [:index, :show]
  
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
      @task_list ||= @task.task_list
    rescue
      return error_status(true, :invalid_task)
    end
    
    respond_to do |format|
      format.html { }
      format.js { @task_content = render_to_string({:partial => 'show', :collection => [@task]}); render :task_update_response }
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
    
    @task = @task_list.tasks.build(task_params)
    @task.created_by = @logged_user
    
    respond_to do |format|
      if @task.save
        MailNotifier.task(@task.user, @task).deliver_now if params[:send_notification] and @task.user
        flash[:notice] = 'ListItem was successfully created.'
        format.html { redirect_back_or_default(project_task_lists_path(@active_project)) }
        format.js { @task_content = render_to_string({:partial => 'show', :collection => [@task]}); render :task_update_response }
        format.xml  { render :xml => @task.to_xml(:root => 'task'), :status => :created, :location => @task }
      else
        format.html { render :action => "new" }
        format.js { @task_content = render_to_string({:partial => 'show', :collection => [@task]}); render :task_update_response }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    authorize! :edit, @task
    
    @task.updated_by = @logged_user

    respond_to do |format|
      if @task.update(task_params)
        MailNotifier.task(@task.user, @task).deliver_now if params[:send_notification] and @task.user
        flash[:notice] = 'ListItem was successfully updated.'
        format.html { redirect_back_or_default(project_task_lists_path(@active_project)) }
        format.js { @task_content = render_to_string({:partial => 'show', :collection => [@task]}); render :task_update_response }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js { @task_content = render_to_string({:partial => 'show', :collection => [@task]}); render :task_update_response }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    authorize! :delete, @task
    
    @task.updated_by = @logged_user
    @task.destroy

    respond_to do |format|
      format.html { redirect_back_or_default(project_task_lists_url(@active_project)) }
      format.js { render :json => { :id => @task.id } }
      format.xml  { head :ok }
    end
  end

  # PUT /tasks/1/status
  # PUT /tasks/1/status.xml
  def status
    authorize! :complete, @task
    
    @task.set_completed(task_params[:completed] == true, @logged_user)
    @task.order = @task_list.tasks.length
    @task.save

    respond_to do |format|
      format.html { redirect_back_or_default(project_task_lists_url(@active_project)) }
      format.js { @task_content = render_to_string({:partial => 'show', :collection => [@task]}); render :task_update_response }
      format.xml  { head :ok }
    end

  end

protected

  def current_tab
    :tasks
  end

  def current_crumb
    case action_name
      when 'new', 'create' then :add_task
      when 'edit', 'update' then :edit_task
      when 'show' then truncate(@task.text, :length => 25)
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :tasks, :url => project_task_lists_path(@active_project)}
    unless @task_list.nil?
      crumbs << {:title => @task_list.name, :url => project_task_list_path(@active_project, :id => @task_list.id)}
    else
      crumbs << {:title => @logged_user.display_name, :url => "/dashboard/my_tasks"}
    end
    crumbs
  end

  def task_params
    params[:task].nil? ? {} : params[:task].permit(:completed, :text, :assigned_to_id, :task_list_id, :estimated_hours)
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
  
  def grab_list_required
    if params[:task_list_id].nil?
      error_status(true, :invalid_task)
      return false
    end
    grab_list
  end

  def load_related_object
    if !params[:task_list_id].nil?
      grab_list_required
      begin
        @task = (@task_list||@active_project).tasks.find(params[:id])
      rescue
        return error_status(true, :invalid_task)
      end
    else
      grab_list
    end
  end
end
