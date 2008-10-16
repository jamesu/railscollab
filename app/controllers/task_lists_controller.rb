class TaskListsController < ApplicationController

  layout 'project_website'

  before_filter :process_session
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /lists
  # GET /lists.xml
  def index
    include_private = @logged_user.member_of_owner?
    
    respond_to do |format|
      format.html {
        @open_task_lists = @active_project.project_task_lists.open(include_private)
        @completed_task_lists = @active_project.project_task_lists.completed(include_private)
        @content_for_sidebar = 'index_sidebar'
      }
      format.xml  {
        conds = include_private ? {} : {'is_private', false}
        @task_lists = @active_project.project_task_lists.find(:all, :conditions => conds)
        render :xml => @task_lists.to_xml(:root => 'task-lists')
      }
    end
  end

  # GET /lists/1
  # GET /lists/1.xml
  def show
    begin
      @task_list = @active_project.project_task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    return error_status(true, :insufficient_permissions) unless @task_list.can_be_seen_by(@logged_user)
    
    include_private = @logged_user.member_of_owner?

    respond_to do |format|
      format.html {
        @open_task_lists = @active_project.project_task_lists.open(include_private)
        @completed_task_lists = @active_project.project_task_lists.completed(include_private)
        @content_for_sidebar = 'index_sidebar'
      }
      format.js {}
      format.xml  { render :xml => @task_list.to_xml(:root => 'task-list') }
    end
  end

  # GET /lists/new
  # GET /lists/new.xml
  def new
    return error_status(true, :insufficient_permissions) unless (ProjectTaskList.can_be_created_by(@logged_user, @active_project))
    
    @task_list = @active_project.project_task_lists.build()
    
    begin
      @task_list.project_milestone = @active_project.project_milestones.find(params[:milestone_id])
      @task_list.is_private = @task_list.project_milestone.is_private
    rescue ActiveRecord::RecordNotFound
      @task_list.milestone_id = 0
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task_list.to_xml(:root => 'task-list') }
    end
  end

  # GET /lists/1/edit
  def edit
    begin
      @task_list = @active_project.project_task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    return error_status(true, :insufficient_permissions) unless (@task_list.can_be_edited_by(@logged_user))
  end

  # POST /lists
  # POST /lists.xml
  def create
    return error_status(true, :insufficient_permissions) unless (ProjectTaskList.can_be_created_by(@logged_user, @active_project))
    
    @task_list = @active_project.project_task_lists.build(params[:task_list])
    @task_list.created_by = @logged_user

    respond_to do |format|
      if @task_list.save
        flash[:notice] = 'List was successfully created.'
        format.html {
          error_status(false, :success_added_task_list)
          redirect_back_or_default(@task_list)
        }
        format.js {}
        format.xml  { render :xml => @task_list.to_xml(:root => 'task-list'), :status => :created, :location => @task_list }
      else
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lists/1
  # PUT /lists/1.xml
  def update
    begin
      @task_list = @active_project.project_task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    return error_status(true, :insufficient_permissions) unless (@task_list.can_be_edited_by(@logged_user))
    
    @task_list.updated_by = @logged_user

    respond_to do |format|
      if @task_list.update_attributes(params[:task_list])
        flash[:notice] = 'List was successfully updated.'
        format.html {
          error_status(false, :success_edited_task_list)
          redirect_back_or_default(@task_list)
        }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lists/1
  # DELETE /lists/1.xml
  def destroy
    begin
      @task_list = @active_project.project_task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    return error_status(true, :insufficient_permissions) unless (@task_list.can_be_deleted_by(@logged_user))
    
    @task_list.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_task_list)
        redirect_to(task_lists_url)
      }
      format.js {}
      format.xml  { head :ok }
    end
  end
  
  # POST /lists/1/reorder
  def reorder
    begin
      @task_list = @active_project.project_task_lists.find(params[:id])
    rescue
      return error_status(true, :invalid_task_list)
    end
    
    return error_status(true, :insufficient_permissions) unless (@task_list.can_be_edited_by(@logged_user))
    
    order = params[:tasks].collect { |id| id.to_i }
    
    @task_list.project_tasks.each do |item|
        idx = order.index(item.id)
        item.order = idx || @task_list.project_tasks.length
        item.save!
    end
    
    respond_to do |format|
      format.html { head :ok }
      format.json { head :ok }
      format.xml  { head :ok }
    end
  end
  
end
