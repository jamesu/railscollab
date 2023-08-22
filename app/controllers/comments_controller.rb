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

class CommentsController < ApplicationController

  layout 'project_website'

  before_filter :process_session
  before_filter :obtain_comment, :except => [:index, :new, :create]
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /comments
  # GET /comments.xml
  def index
    # Grab related object class + id
    object_class, object_id = find_comment_object
    if object_class.nil?
      error_status(true, :invalid_request)
      redirect_back_or_default :controller => 'dashboard', :action => 'index'
      return
    end
    
    # Find object
    @commented_object = object_class.find(object_id)
    return error_status(true, :invalid_object) if @commented_object.nil?
    
    # Check permissions
    authorize! :show, @commented_object
    
    @comments = @logged_user.member_of_owner? ? @commented_object.comments : @commented_object.comments.is_public
    
    respond_to do |format|
      format.html {}
      format.xml { render :xml => @comments.to_xml(:root => 'comments', 
                                                   :only => [:id,
                                                             :text,
                                                             :author_name, 
                                                             :created_by_id, 
                                                             :created_on, 
                                                             :is_anonymous, 
                                                             :is_private,
                                                             :attached_files_count]) }
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    authorize! :show, @comment
    
    respond_to do |format|
      format.html {}
      format.xml {
        fields = @logged_user.is_admin? ? [] : [:author_email, :author_homepage]
        render :xml => @comment.to_xml(:root => 'comment', :except => fields) 
      }
    end
  end

  # GET /comments/new
  # GET /comments/new.xml
  def new
    # Grab related object class + id
    object_class, object_id = find_comment_object
    if object_class.nil?
      error_status(true, :invalid_request)
      redirect_back_or_default :controller => 'dashboard', :action => 'index'
      return
    end
    
    # Find object
    @commented_object = object_class.find(object_id)
    return error_status(true, :invalid_object) if @commented_object.nil?
    
    # Check permissions
    authorize! :comment, @commented_object

    @comment = Comment.new()
    @comment.rel_object = @commented_object
    
    respond_to do |format|
      format.html {
        @active_project = @commented_object.project
        @active_projects = @logged_user.active_projects
      }
      format.xml  { render :xml => @comment.to_xml(:root => 'comment') }
    end
  end

  # GET /comments/1/edit
  def edit
    authorize! :edit, @comment
    
    @commented_object = @comment.rel_object
	  @active_project = @commented_object.project
  end

  # POST /comments
  # POST /comments.xml
  def create
    # Grab related object class + id
    object_class, object_id = find_comment_object
    if object_class.nil?
      error_status(true, :invalid_request)
      redirect_back_or_default :controller => 'dashboard', :action => 'index'
      return
    end
    
    # Find object
    @commented_object = object_class.find(object_id)
    return error_status(true, :invalid_object) if @commented_object.nil?
    
    # Check permissions
    authorize! :comment, @commented_object

    @comment = Comment.new()
    @comment.rel_object = @commented_object
    
    saved = false
    estatus = :success_added_comment
    
    Comment.transaction do
      comment_attribs = comment_params

      @comment.attributes = comment_attribs
      @comment.rel_object = @commented_object
      @comment.created_by = @logged_user
      @comment.author_homepage = request.remote_ip
      
      saved = @comment.save
      
      if saved
        # Notify everyone
        @commented_object.send_comment_notifications(@comment)

        # Subscribe if Message
        @commented_object.ensure_subscribed(@logged_user) if @commented_object.class == Message

        if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @comment, @logged_user, @comment.is_private) != params[:uploaded_files].length)
          estatus = :success_added_comment_error_files
        end
      end
    end
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, estatus)
          redirect_back_or_default(@comment.object_url)
        }
        format.xml  { render :xml => @comment.to_xml(:root => 'comment'), :status => :created, :location => @comment.object_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    authorize! :edit, @comment

    @commented_object = @comment.rel_object
  	@active_project = @commented_object.project

  	saved = false
  	estatus = :success_edited_comment

    Comment.transaction do
      comment_attribs = comment_params

      @comment.attributes = comment_attribs
      @comment.updated_by = @logged_user
      
      saved = @comment.save
      estatus
      if saved
        if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @comment, @logged_user, @comment.is_private) != params[:uploaded_files].length)
          estatus = :success_edited_comment_error_files
        end
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, estatus)
          redirect_back_or_default(@commented_object.object_url)
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    authorize! :delete, @comment
    
    @comment.updated_by = @logged_user
    @comment.destroy
    
    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_comment)
        redirect_back_or_default(project_path(:id => @active_project.id))
      }
      format.xml  { head :ok }
    end
  end

private

  def find_comment_object
    rmap = comment_route_map
    rmap.each do |rtc|
      value = params[rtc[0]]
      if !value.nil?
        return Kernel.const_get(rtc[1]) || nil, value.to_i
      end
    end
    
    return nil, nil
  end
  
  def obtain_comment
    @active_projects = @logged_user.active_projects

    begin
      @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_comment)
      redirect_back_or_default project_path(:id => @active_project.id)
      return false
    end

    true
  end
  
  def comment_route_map
    [[:message_id, :Message],
     [:milestone_id, :Milestone],
     [:file_id, :ProjectFile],
     [:task_id, :Task],
     [:task_list_id, :TaskList]]
  end

protected

  def comment_params
    params[:comment].nil? ? {} : params[:comment].permit(:text, :is_private, :author_name, :author_email)
  end

end
