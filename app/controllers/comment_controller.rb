=begin
RailsCollab
-----------

Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)

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

class CommentController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete ],
  		 :add_flash => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'dashboard' }
  
  filter_parameter_logging :uploaded_files
  
  before_filter :obtain_comment, :except => [:add]
  after_filter  :user_track
  
  def add
    rel_object_type = params[:object_type]
    rel_object_id = params[:object_id]
    
    if (rel_object_type.nil? or rel_object_id.nil?) or (!['ProjectMessage', 'ProjectMilestone', 'ProjectTask', 'ProjectTaskList', 'ProjectFile'].include?(rel_object_type))
      error_status(true, :invalid_request)
      redirect_back_or_default :controller => 'dashboard', :action => 'index'
      return
    end
    
    # Find object we want to comment
    begin
       @commented_object = Kernel.const_get(rel_object_type).find(params[:object_id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_object)
      redirect_back_or_default :controller => 'dashboard', :action => 'index'
      return
    end
	
	@active_project = @commented_object.project
    @active_projects = @logged_user.active_projects
    
    if not @commented_object.comment_can_be_added_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default @commented_object.object_url
      return
    end
    
    @comment = Comment.new()
    
    case request.method
	  when :get
		render :layout => 'dashboard'
      when :post
        Comment.transaction do
        
      	comment_attribs = params[:comment]
      	
      	@comment.attributes = comment_attribs
      	@comment.rel_object = @commented_object
      	@comment.created_by = @logged_user
      	@comment.author_homepage = request.remote_ip
      	
        if @comment.save
          # Notify everyone
          @commented_object.send_comment_notifications(@comment)
          
          # Subscribe if ProjectMessage
          @commented_object.ensure_subscribed(@logged_user) if @commented_object.class == ProjectMessage
          
          if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @comment, @logged_user, @comment.is_private) != params[:uploaded_files].length)
			error_status(false, :success_added_comment_error_files)
		  else
			error_status(false, :success_added_comment)
          end
          redirect_back_or_default @commented_object.object_url
        else
          render :layout => 'dashboard'
        end
        
        end
    end
  end
  
  def edit
    if not @comment.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return
    end
    
    @commented_object = @comment.rel_object
	@active_project = @commented_object.project
    
    case request.method
      when :post
        Comment.transaction do
        
        comment_attribs = params[:comment]
        
        @comment.attributes = comment_attribs
        @comment.updated_by = @logged_user
        
        if @comment.save
          if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @comment, @logged_user, @comment.is_private) != params[:uploaded_files].length)
			error_status(false, :success_edited_comment_error_files)
		  else
			error_status(false, :success_edited_comment)
          end
          redirect_back_or_default @commented_object.object_url
        end
        
        end
    end
  end
  
  def delete
    if not @comment.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return
    end
    
    @comment.updated_by = @logged_user
    @comment.destroy
    
    error_status(false, :success_deleted_comment)
    redirect_back_or_default :controller => 'project', :action => 'overview'
  end
  
private

  def obtain_comment
    @active_projects = @logged_user.active_projects
     
    begin
       @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_comment)
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return false
    end
    
    return true
  end
  
end
