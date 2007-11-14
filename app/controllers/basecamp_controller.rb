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

# All-inclusive implementation of the BaseCamp API

class BasecampController < ApplicationController

  layout nil

  before_filter :login_required
  before_filter :ensure_content
  before_filter :process_session
  #after_filter  :user_track
  
  # project/list
  def projects_list
  end
  
  def contacts_companies
  	if !@logged_user.member_of_owner?
  		render :text => 'Error', :status => 403
  		return
  	end
  	
  	@companies = Company.owner.clients
  end
  
  # /projects/#{project-id}/attachment_categories
  def projects_attachment_categories
	@folders = @active_project.project_folders
  end
  
  # /projects/#{project-id}/post_categories
  def projects_post_categories
	@categories = @active_project.project_message_categories
  end
  
  # /msg/comment/#{comment_id}
  def msg_comment
    begin
       @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @comment.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
  end
  
  # /msg/comments/#{message_id}
  def msg_comments
    begin
       @message = ProjectMessage.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @message.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
	
	@comments = @message.comments.reject do |comment| 
		!comment.can_be_seen_by(@logged_user)
	end
  end
  
  # /msg/create_comment
  def msg_create_comment
  	comment_attribs = @request_fields[:comment]
  	    
    begin
       @message = ProjectMessage.find(comment_attribs[:post_id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @message.comment_can_be_added_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @comment = Comment.new(:text => comment_attribs[:body])
    @comment.rel_object = @message
    @comment.created_by = @logged_user
    
    @comment.is_private = false
    
    if @comment.save
    	ApplicationLog.new_log(@comment, @logged_user, :add, @comment.is_private, @message.project)
    	
    	# Notify everyone
    	@message.send_comment_notifications(@comment)
    else
    	render :text => 'Error', :status => 500
    	return
    end
    
    render :file => 'basecamp/msg_comment'
  end
  
  # /projects/#{project_id}/msg/create
  def projects_msg_create
    if not ProjectMessage.can_be_created_by(@logged_user, @active_project)
      render :text => 'Error', :status => 403
      return
    end
    
    post_attribs = @request_fields[:post]
    
    @message = ProjectMessage.new(
    		:category_id => post_attribs[:category_id],
    		:title => post_attribs[:title],
    		:text => post_attribs[:body],
    		:additional_text => post_attribs[:extended_body]
    )
    
    @message.project = @active_project
    @message.created_by = @logged_user
    
    @message.is_private = @logged_user.member_of_owner? ? post_attribs[:private] : false
    @message.is_important = false
    @message.comments_enabled = true
    @message.anonymous_comments_enabled = false
    
    if @message.save
    	ApplicationLog.new_log(@message, @logged_user, :add, @message.is_private, @message.project)
    	
    	# Notify specified users
    	if !@request_fields[:notify].nil?
    		valid_users = @request_fields[:notify].collect do |user_id|
    			real_id = user_id.to_i
    			
    			if ProjectUser.find(:all, :conditions => ["user_id = ? AND project_id = ?", real_id, @active_project.id]).length > 0
    				real_id
    			else
    				nil
    			end
    		end
    	
    		User.find(:all, :conditions => "id IN (#{valid_users.compact.join(',')})").each do |user|
    			@message.send_notification(user)
    		end
    	end
    	
    	# Handle file attachments
    	if !@request_fields[:attachments].nil?
    		# TODO
    	end
    else
    	render :text => 'Error', :status => 500
    	return
    end
    
    render :file => 'basecamp/msg_update'
  end
  
  # /msg/delete_comment/#{comment_id}
  def msg_delete_comment
    begin
       @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @comment.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    ApplicationLog.new_log(@comment, @logged_user, :delete, true, @comment.rel_object.project)
    @comment.destroy
    
    render :file => 'basecamp/msg_comment'
  end
  
  # /msg/delete/#{message_id}
  def msg_delete
    begin
       @message = ProjectMessage.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @message.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    ApplicationLog.new_log(@comment, @logged_user, :delete, true)
    @message.destroy

    render :file => 'basecamp/msg_update'
  end
  
  # /msg/get/#{message_ids}
  def msg_get
  end
  
  # /projects/#{project_id}/msg/archive
  def projects_msg_archive
  end
  
  # /projects/#{project_id}/msg/cat/#{category_id}/archive
  def projects_msg_cat_archive
  	render :file => 'basecamp/projects_msg_archive'
  end
  
  # /msg/update_comment
  def msg_update_comment   
    begin
       @comment = Comment.find(@request_fields[:comment_id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @comment.can_be_edited_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    comment_attribs = @request_fields[:comment]
    
    @comment.updated_by = @logged_user
    @comment.text = comment_attribs[:body]
    
    if @comment.save
    	ApplicationLog.new_log(@comment, @logged_user, :edit, @comment.is_private, @comment.rel_object.project)
    else
    	render :text => 'Error', :status => 500
    	return
    end
    
    render :file => 'basecamp/msg_comment'
  end
  
  # /msg/update/#{message_id}
  def msg_update
    begin
       @message = ProjectMessage.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
  	
    if not @message.can_be_edited_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    post_attribs = @request_fields[:post]
    
    @message.attributes = {
    		:category_id => post_attribs[:category_id],
    		:title => post_attribs[:title],
    		:text => post_attribs[:body],
    		:additional_text => post_attribs[:extended_body]
    }
    
    @message.updated_by = @logged_user
    @message.is_private = @logged_user.member_of_owner? ? post_attribs[:private] : false
    
    if @message.save
    	ApplicationLog.new_log(@message, @logged_user, :edit, @message.is_private, @message.project)
    	
    	# Notify specified users
    	# TODO
    	
    	# Handle file attachments
    	if !@request_fields[:attachments].nil?
    		# TODO
    	end
    else
    	render :text => 'Error', :status => 500
    	return
    end
  end
  
private

  def ensure_content
  	if request.accepts.first == Mime::XML
  		@request_fields = params[:request]
  		true
  	else
  		render :text => 'Error', :status => 500
  		false
  	end
  end
  
end
