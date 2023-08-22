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
  helper 'project_items'

  before_filter :process_session
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /task_lists
  # GET /task_lists.xml
  def index
    include_private = @logged_user.member_of_owner?
    
    respond_to do |format|
      format.html {
        index_lists(include_private)
      }
      format.js {
        index_lists(include_private)
        render :template => 'task_lists/index'
      }
      format.xml  {
        conds = include_private ? {} : {'is_private' => false}
        @task_lists = @active_project.task_lists.where(conds)
        render :xml => @task_lists.to_xml(:root => 'task-lists')
      }
    end
  end

  # GET /task_lists/1
  # GET /task_lists/1.xml
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
      
      format.xml  { render :xml => @task_list.to_xml(:root => 'task-list') }
    end
  end

  # GET /task_lists/new
  # GET /task_lists/new.xml
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
      
      format.xml  { render :xml => @task_list.to_xml(:root => 'task-list') }
    end
  end

  # GET /task_lists/1/edit
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
          redirect_back_or_default(@task_list)
        }
        format.js { return index }
        format.xml  { render :xml => @task_list.to_xml(:root => 'task-list'), :status => :created, :location => @task_list }
      else
        format.html { render :action => "new" }
        
        format.xml  { render :xml => @list.errors, :status => :unprocessable_entity }
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
      if @task_list.update_attributes(task_list_params)
        flash[:notice] = 'List was successfully updated.'
        format.html {
          error_status(false, :success_edited_task_list)
          redirect_back_or_default(@task_list)
        }
        
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        
        format.xml  { render :xml => @list.errors, :status => :unprocessable_entity }
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
        redirect_to(task_lists_url)
      }
      format.js { index_lists(@logged_user.member_of_owner?) }
      format.xml  { head :ok }
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
      format.xml  { head :ok }
    end
  end

protected

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
