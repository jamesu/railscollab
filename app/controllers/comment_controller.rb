=begin
RailsCollab
-----------
Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class CommentController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'dashboard' }

  before_filter :login_required
  before_filter :process_session
  before_filter :obtain_comment, :except => [:add]
  after_filter  :user_track
  
  def add
    rel_object_type = params[:object_type]
    rel_object_id = params[:object_id]
    
    if (rel_object_type.nil? or rel_object_id.nil?) or (!['ProjectMessage', 'ProjectMilestone', 'ProjectTask', 'ProjectTaskList', 'ProjectFile'].include?(rel_object_type))
      flash[:flash_error] = "Invalid request"
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return
    end
    
    # Find object we want to comment
    begin
       @commented_object = Kernel.const_get(rel_object_type).find(params[:object_id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid object"
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return
    end
    
    if not @commented_object.comment_can_be_added_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default @commented_object.object_url
      return
    end
    
    @comment = Comment.new()
    
    case request.method
      when :post
      	comment_attribs = params[:comment]
      	
      	@comment.update_attributes(comment_attribs)
      	@comment.rel_object = @commented_object
      	@comment.created_by = @logged_user
      	
      	@comment.is_private = @logged_user.member_of_owner? ? comment_attribs[:is_private] : false
      	
        if @comment.save
          ApplicationLog.new_log(@comment, @logged_user, :add, @comment.is_private, @commented_object.project)
          
          # TODO: notifications
          
          
          ProjectFile.handle_files(params[:uploaded_files], @comment, @logged_user, @comment.is_private)
          
          flash[:flash_success] = "Successfully added comment"
          redirect_back_or_default @commented_object.object_url
        end
    end
  end
  
  def edit    
    if not @comment.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return
    end
    
    @commented_object = @comment.rel_object
    
    case request.method
      when :post
        comment_attribs = params[:comment]
        
        @comment.update_attributes(comment_attribs)
        @comment.updated_by = @logged_user
        
        @comment.is_private = @logged_user.member_of_owner? ? comment_attribs[:is_private] : false
        
        if @comment.save
          ApplicationLog.new_log(@comment, @logged_user, :edit, @comment.is_private, @commented_object.project)
          
          # TODO: notifications
          
          ProjectFile.handle_files(params[:uploaded_files], @comment, @logged_user, @comment.is_private)
          
          flash[:flash_success] = "Successfully updated comment"
          redirect_back_or_default @commented_object.object_url
        end
    end
  end
  
  def delete
    if not @comment.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return
    end
    
    ApplicationLog.new_log(@comment, @logged_user, :delete, true,  @comment.rel_object.project)
    @comment.destroy
    
    flash[:flash_success] = "Successfully deleted comment"
    redirect_back_or_default :controller => 'project', :action => 'overview'
  end
  
private

  def obtain_comment
    begin
       @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid comment"
      redirect_back_or_default :controller => 'project', :action => 'overview'
      return false
    end
    
    return true
  end
  
end
