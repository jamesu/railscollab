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

class MessageController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete, :subscribe, :unsubscribe, :delete_category ],
  		 :add_flash => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'dashboard' }
  
  filter_parameter_logging :uploaded_files
  
  before_filter :process_session
  before_filter :obtain_message, :except => [:index, :add, :category, :add_category, :edit_category, :delete_category]
  after_filter  :user_track
  
  def index
    current_page = params[:page].to_i
    current_page = 0 unless current_page > 0
    page = {:size => AppConfig.messages_per_page, :current => current_page}
    
    if @logged_user.member_of_owner?
      @messages = @active_project.project_messages.find(:all, :page => page)
    else
      @messages = @active_project.project_messages.find(:all, :conditions => ['is_private = ?', false], :page => page)
    end
    
    @pagination = []
    @messages.page_count.times {|page| @pagination << page+1}
    
    @message_categories = @active_project.project_message_categories
    @important_messages = @active_project.project_messages.important(@logged_user.member_of_owner?)
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  def view
    if not @message.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    @subscribers = @message.subscribers
    @content_for_sidebar = 'view_sidebar'
  end
  
  # Categories
  
  def category
    begin
      @category ||= @active_project.project_message_categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_message_category)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    if !@category.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
    end
    
    current_page = params[:page].to_i
    current_page = 0 unless current_page > 0
    
    msg_conditions = {'category_id' => @category.id}
    msg_conditions['is_private'] = false unless @logged_user.member_of_owner?
    @messages = @active_project.project_messages.find(:all, :conditions => msg_conditions, :page => {:size => AppConfig.messages_per_page, :current => current_page})
    @pagination = []
    @messages.page_count.times {|page| @pagination << page+1}
    
    @current_category = @category
    @page = current_page
    @message_categories = @active_project.project_message_categories
    important_conditions = {'is_important' => true}
    important_conditions['is_private'] = false unless @logged_user.member_of_owner?
    @important_messages = @active_project.project_messages.find(:all, :conditions => important_conditions)
       
    @content_for_sidebar = 'index_sidebar'
    
    render :template => 'message/index'
  end
  
  def add_category
    @category = ProjectMessageCategory.new
    
    if not ProjectMessageCategory.can_be_created_by(@logged_user, @active_project)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    case request.method
      when :post
        category_attribs = params[:category]
        @category.attributes = category_attribs
        @category.project = @active_project
        
        if @category.save
          ApplicationLog::new_log(@category, @logged_user, :add)
          
          error_status(false, :success_added_message_category)
          redirect_back_or_default :controller => 'message'
        end
    end
  end
  
  def edit_category
    begin
      @category ||= @active_project.project_message_categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_message_category)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    if not @category.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    case request.method
      when :post
        category_attribs = params[:category]
        
        @category.attributes = category_attribs
        
        if @category.save
          ApplicationLog::new_log(@category, @logged_user, :edit)
          
          error_status(false, :success_edited_message_category)
          redirect_back_or_default :controller => 'message'
        end
    end
  end
  
  def delete_category
    begin
      @category ||= @active_project.project_message_categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_message_category)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    if not @category.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    ApplicationLog::new_log(@category, @logged_user, :delete)
    @category.destroy
    
    error_status(false, :success_deleted_message_category)
    redirect_back_or_default :controller => 'message'
  end

  
  # Messages
  
  def add
    if not ProjectMessage.can_be_created_by(@logged_user, @active_project)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    @message = ProjectMessage.new
    
    case request.method
      when :get
	    # Grab default milestone
	    begin
	      @milestone = @active_project.project_milestones.find(params[:milestone_id])
	    rescue ActiveRecord::RecordNotFound
	      @milestone = nil
	    end
	    
	    if @milestone
	      @message.milestone_id = @milestone.id
	    end
		
		# Grab default category
	    begin
	      @category = @active_project.project_message_categories.find(params[:category_id])
	    rescue ActiveRecord::RecordNotFound
	      @category = nil
	    end
	    
	    if @category
	      @message.category_id = @category.id
	    else
	      @category = @active_project.project_message_categories.find(:first, :conditions => ['name = ?', AppConfig.default_project_message_category])
	    end
	    
	    @message.comments_enabled = true unless (params[:message] and params[:message].has_key?(:comments_enabled))

      when :post
        message_attribs = params[:message]
        
        @message.attributes = message_attribs
        
        @message.project = @active_project
        @message.created_by = @logged_user
        
        if @message.save
          @message.tags = message_attribs[:tags]
		  
          # Notify selected users
          if !params[:notify_user].nil?
			valid_users = params[:notify_user].collect do |user_id|
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
		  
		  # Subscribe
          @message.ensure_subscribed(@logged_user) if @message.class == ProjectMessage
          
          if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private) != params[:uploaded_files].length)
			error_status(false, :success_added_message_failed_attachments)
		  else
			error_status(false, :success_added_message)
          end
          redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
        end
    end
  end
  
  def edit
    if not @message.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    case request.method
      when :post
        message_attribs = params[:message]
        
        @message.attributes = message_attribs
        
        @message.updated_by = @logged_user
        @message.tags = message_attribs[:tags]
        
        if @message.save
          if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private) != params[:uploaded_files].length)
			error_status(false, :success_edited_message_failed_attachments)
		  else
			error_status(false, :success_edited_message)
          end          
          redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
        end
    end
  end
  
  def update_options
  	edit
  end
  
  def delete
    if not @message.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
    
    @message.updated_by = @logged_user
    @message.destroy
    
    error_status(false, :success_deleted_message)
    redirect_back_or_default :controller => 'dashboard'
  end
  
  def subscribe
    if not @message.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
	
	@message.ensure_subscribed(@logged_user) if @message.class == ProjectMessage

    error_status(false, :success_subscribed_to_message)
    redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
  end
  
  def unsubscribe
    if not @message.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'message'
      return
    end
	
	@message.subscribers.delete(@logged_user)

    error_status(false, :success_unsubscribed_from_message)
    redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
  end

private

   def obtain_message
     begin
        @message = @active_project.project_messages.find(params[:id])
     rescue ActiveRecord::RecordNotFound
       error_status(true, :invalid_message)
       redirect_back_or_default :controller => 'message'
       return false
     end
     
     return true
   end  
end
