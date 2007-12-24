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

class TaskController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete_list, :delete_task, :open_task, :complete_task ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'dashboard' }
  
  before_filter :login_required
  before_filter :process_session
  after_filter  :user_track, :only => [:index, :view_list]
  
  def index
    include_private = @logged_user.member_of_owner?
    @open_task_lists = @active_project.project_task_lists.open(include_private)
    @completed_task_lists = @active_project.project_task_lists.completed(include_private)
    @content_for_sidebar = 'index_sidebar'
  end
  
  # Task lists
  def view_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task list"
      redirect_back_or_default :controller => 'task', :action => 'index'
      return
    end
    
    if not @task_list.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task', :action => 'index'
      return
    end
    
    include_private = @logged_user.member_of_owner?
    @open_task_lists = @active_project.project_task_lists.open(include_private)
    @completed_task_lists = @active_project.project_task_lists.completed(include_private)
    @content_for_sidebar = 'index_sidebar'
  end
  
  def add_list    
    if not ProjectTaskList.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task_list = ProjectTaskList.new
    
    case request.method
      when :get
        begin
          @task_list.project_milestone = ProjectMilestone.find(params[:milestone_id])
          @task_list.is_private = @task_list.project_milestone.is_private
        rescue ActiveRecord::RecordNotFound
          @task_list.milestone_id = 0
          @task_list.is_private = false
        end
      when :post
        task_attribs = params[:task_list]
        
        @task_list.attributes = task_attribs
        @task_list.created_by = @logged_user
        @task_list.project = @active_project
        
        if @task_list.save
          @task_list.tags = task_attribs[:tags]
        
          flash[:flash_success] = "Successfully added task"
          redirect_back_or_default :controller => 'task'
        end
    end 
  end
  
  def edit_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task_list.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    case request.method
      when :post
        task_attribs = params[:task_list]
        
        @task_list.attributes = task_attribs
        
        @task_list.updated_by = @logged_user
        @task_list.tags = task_attribs[:tags]
        
        if @task_list.save
          flash[:flash_success] = "Successfully modified task"
          redirect_back_or_default :controller => 'task'
        end
    end 
  end
  
  def delete_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task_list.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task_list.updated_by = @logged_user
    @task_list.destroy
    
    flash[:flash_success] = "Successfully deleted task"
    redirect_back_or_default :controller => 'milestone'
  end
  
  def reorder_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task_list.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end

    case request.method
      when :post
		tasks = @task_list.project_tasks
		if params.has_key? :list
			order = params[:list].collect { |id| id.to_i }
		elsif params.has_key? :items
			order = params[:items].sort{ |val1,val2| val1[1].to_i <=> val2[1].to_i }.collect{ |val| val[0].to_i }
		else
			render :text => 'Invalid', :status => 403
		end
		
		tasks.each do |task|
			idx = order.index(task.id)
			task.set_order(idx.nil? ? 0 : idx, @logged_user)
			task.save!
		end
		
		ApplicationLog.new_log(@task_list, @logged_user, :edit, @task_list.is_private)
		
		if params.has_key? :list
			render :text => ''
			return
		end
		
		@task_list.project_tasks(true) # Reload
    end
	
	render :template => 'task/reorder_tasks'
  end
  
  # Tasks
  def add_task
    begin
      @task_list = ProjectTaskList.find(params[:task_list_id])
    rescue ActiveRecord::RecordNotFound
	  flash[:flash_error] = "Invalid task list"
	  if params[:partial]
		render :text => '403 Invalid', :status => 403
	  else
		redirect_back_or_default :controller => 'task'
	  end
	  
	  return
    end
    
    if not ProjectTask.can_be_created_by(@logged_user, @task_list)
	  flash[:flash_error] = "Insufficient permissions"
      if params[:partial]
		render :text => '403 Invalid', :status => 403
	  else
		redirect_back_or_default :controller => 'task'
	  end
	  
	  return
    end
    
    @task = ProjectTask.new
    
    case request.method
      when :post
        task_attribs = params[:task]
        
        @task.attributes = task_attribs
        @task.created_by = @logged_user
        @task.task_list = @task_list
        
        if @task.save
          flash[:flash_success] = "Successfully added task"
		  
		  if params[:partial]
			render :partial => 'task/task_item', :collection => [@task], :locals => {:tprefix => "openTasksList#{@task_list.id}"}
		  else
			redirect_back_or_default :controller => 'task'
		  end
		elsif params[:partial]
			render :text => 'Validation failed', :status => 400
        end
    end 
  end
  
  def edit_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    case request.method
      when :post
        task_attribs = params[:task]
        
        @task.attributes = task_attribs
        @task.updated_by = @logged_user
        
        if @task.save
          flash[:flash_success] = "Successfully modified task"
          redirect_back_or_default :controller => 'task'
        end
    end 
  end
  
  def delete_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task.updated_by = @logged_user
    @task.destroy
    
    flash[:flash_success] = "Successfully deleted task"
    redirect_back_or_default :controller => 'milestone'
  end
  
  def complete_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.completed_on.nil?
      flash[:flash_error] = "Task already completed"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task.set_completed(true, @logged_user)
    
    if not @task.save
      flash[:flash_error] = "Error saving"
    end
    
    redirect_back_or_default :controller => 'task'
  end
  
  def open_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if @task.completed_on.nil?
      flash[:flash_error] = "Task already open"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task.set_completed(false, @logged_user)
    
    if not @task.save
      flash[:flash_error] = "Error saving"
    end
    
    redirect_back_or_default :controller => 'task'
  end
end
