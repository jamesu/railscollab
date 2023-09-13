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

class TaskListsController < ApplicationController

  layout 'project_website'
  

  
  after_action  :user_track, only: [:index, :show]
  
  
  
  def index
    include_private = @logged_user.member_of_owner?
    
    respond_to do |format|
      format.html {
        index_lists(include_private)
      }
      format.js {
        index_lists(include_private)
        render template: 'task_lists/index'
      }
      format.json  {
        conds = include_private ? {} : {'is_private' => false}
        @task_lists = @active_project.task_lists.where(conds)
        render json: @task_lists.to_json
      }
    end
  end

  
  
  def show
    begin
      @task_list = @active_project.task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    authorize! :show, @task_list

    respond_to do |format|
      format.html {
        index_lists(@logged_user.member_of_owner?)
      }
      
      format.json  { render json: @task_list.to_json }
    end
  end

  
  
  def new
    authorize! :create_task_list, @active_project
    
    @task_list = @active_project.task_lists.build()
    
    begin
      @task_list.milestone = @active_project.milestones.find(params[:milestone_id])
      @task_list.is_private = @task_list.milestone.is_private
    rescue ActiveRecord::RecordNotFound
      @task_list.milestone_id = 0
    end
    
    respond_to do |format|
      format.html # new.html.erb
      
      format.json  { render json: @task_list.to_json }
    end
  end

  
  def edit
    begin
      @task_list = @active_project.task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    authorize! :edit, @task_list
  end

  # POST /task_lists
  # POST /task_lists.xml
  def create
    authorize! :create_task_list, @active_project
    
    @task_list = @active_project.task_lists.build(task_list_params)
    @task_list.created_by = @logged_user

    respond_to do |format|
      if @task_list.save
        flash[:notice] = 'List was successfully created.'
        format.html {
          error_status(false, :success_added_task_list)
          redirect_back_or_default(@task_list.object_url)
        }
        format.js { return index }
        format.json  { render json: @task_list.to_json, status: :created, location: @task_list }
      else
        format.html { render action: "new" }
        
        format.json  { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /task_lists/1
  # PUT /task_lists/1.xml
  def update
    begin
      @task_list = @active_project.task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    authorize! :edit, @task_list
    
    @task_list.updated_by = @logged_user

    respond_to do |format|
      if @task_list.update(task_list_params)
        flash[:notice] = 'List was successfully updated.'
        format.html {
          error_status(false, :success_edited_task_list)
          redirect_back_or_default(@task_list.object_url)
        }
        
        format.json  { head :ok }
      else
        format.html { render action: "edit" }
        
        format.json  { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /task_lists/1
  # DELETE /task_lists/1.xml
  def destroy
    begin
      @task_list = @active_project.task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    authorize! :delete, @task_list

    @on_page = (params[:on_page] || '').to_i == 1
    @removed_id = @task_list.id
    @task_list.updated_by = @logged_user
    @task_list.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_task_list)
        redirect_to(project_task_lists_url(@active_project))
      }
      format.js { index_lists(@logged_user.member_of_owner?) }
      format.json  { head :ok }
    end
  end
  
  # POST /task_lists/1/reorder
  def reorder
    begin
      @task_list = @active_project.task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    authorize! :edit, @task_list
    
    order = (params[:tasks]||[]).collect { |id| id.to_i }
    
    @task_list.tasks.each do |item|
        idx = order.index(item.id)
        item.order = idx || @task_list.tasks.length
        item.save!
    end
    
    respond_to do |format|
      format.html { head :ok }
      format.json { head :ok }
    end
  end

protected

  def current_tab
    :tasks
  end

  def current_crumb
    case action_name
      when 'index' then :tasks
      when 'new', 'create' then :add_task_list
      when 'edit', 'update' then :edit_task_list
      when 'show' then @task_list.name
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {title: :tasks, url: project_task_lists_path(@active_project)} unless action_name == 'index'
    crumbs
  end

  def page_actions
    @page_actions = []

    if action_name == 'index'
      if can?(:create_task_list, @active_project)
        @page_actions << {title: :add_task_list, :url=> new_project_task_list_path(@active_project), ajax: true}
      end
    end

    @page_actions
  end

  def load_related_object
    begin
      @task_list = @active_project.task_lists.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_task_list, {}, false)
      redirect_back_or_default project_task_lists_path(@active_project)
      return false
    end

    true
  end

  def task_list_params
    params[:task_list].nil? ? {} : params[:task_list].permit(:name, :priority, :description, :milestone_id, :is_private, :tags)
  end


  def index_lists(include_private)
    @open_task_lists = @active_project.task_lists.is_open
    @open_task_lists = @open_task_lists.is_public unless include_private
    @completed_task_lists = @active_project.task_lists.completed
    @completed_task_lists = @completed_task_lists.is_public unless include_private
    @content_for_sidebar = 'index_sidebar'
  end

end
