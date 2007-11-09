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

class MessageController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete, :subscribe, :unsubscribe ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'dashboard' }
  
  before_filter :login_required
  before_filter :process_session
  before_filter :obtain_message, :except => [:index, :add]
  after_filter  :user_track
  
  def index
    current_page = params[:page].to_i
    current_page = 0 unless current_page > 0
    
    msg_conditions = @logged_user.member_of_owner? ? "project_id = ?" : "project_id = ? AND is_private = false"
    
    @messages = ProjectMessage.find(:all, :conditions => [msg_conditions, @active_project.id], :page => {:size => AppConfig.messages_per_page, :current => current_page}, :order => 'created_on DESC')
    @pagination = []
    @messages.page_count.times {|page| @pagination << page+1}
    
    @important_messages = ProjectMessage.find(:all, :conditions => [msg_conditions + " AND is_important = true", @active_project.id], :order => 'created_on DESC')
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  def view
    if not @message.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'message'
      return
    end
    
    @subscribers = @message.subscribers
    @content_for_sidebar = 'view_sidebar'
  end
  
  # Messages
  
  def add
    if not ProjectMessage.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'message'
      return
    end
    
    @message = ProjectMessage.new
    
    case request.method
      when :get
	    begin
	      @milestone = ProjectMilestone.find(params[:milestone_id])
	    rescue ActiveRecord::RecordNotFound
	      @milestone = nil
	    end
	    
	    if @milestone
	    	@message.milestone_id = @milestone.id
	    end

      when :post
        message_attribs = params[:message]
        
        # TODO: set subscribers, handle file uploads
        @message.update_attributes(message_attribs)
        
        @message.project = @active_project
        @message.created_by = @logged_user
        @message.comments_enabled = true
        
        if @logged_user.member_of_owner?
        	# These are reserved
        	@message.is_private = message_attribs[:is_private]
        	@message.is_important = message_attribs[:is_important]
        	@message.comments_enabled = message_attribs[:comments_enabled]
        	@message.anonymous_comments_enabled = message_attribs[:anonymous_comments_enabled]
        end
        
        if @message.save
          ApplicationLog.new_log(@message, @logged_user, :add, @message.is_private)
          
          @message.tags = message_attribs[:tags]
          # TODO: notifications
          
          ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private)
          
          flash[:flash_success] = "Successfully added message"
          redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
        end
    end
  end
  
  def edit
    if not @message.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'message'
      return
    end
    
    case request.method
      when :post
        message_attribs = params[:message]
        
        @message.update_attributes(message_attribs)
        
        @message.updated_by = @logged_user
        @message.tags = message_attribs[:tags]
        
        if @logged_user.member_of_owner?
        	# These are reserved
        	@message.is_private = message_attribs[:is_private]
        	@message.is_important = message_attribs[:is_important]
        	@message.comments_enabled = message_attribs[:comments_enabled]
        	@message.anonymous_comments_enabled = message_attribs[:anonymous_comments_enabled]
        end
        
        if @message.save
          ApplicationLog.new_log(@message, @logged_user, :edit, @message.is_private)
          
          # TODO: notifications
          
          ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private)
          
          flash[:flash_success] = "Successfully updated message"
          redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
        end
    end
  end
  
  def update_options
  	edit
  end
  
  def delete
    if not @message.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'message'
      return
    end
    
    ApplicationLog.new_log(@message, @logged_user, :delete, true)
    @message.destroy
    
    flash[:flash_success] = "Successfully deleted message"
    redirect_back_or_default :controller => 'dashboard'
  end
  
  def subscribe
    if not @message.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'message'
      return
    end
	
	begin
		@message.subscribers.find(@logged_user.id)
	rescue ActiveRecord::RecordNotFound
		@message.subscribers << @logged_user
	end

    flash[:flash_success] = "Successfully subscribed to message"
    redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
  end
  
  def unsubscribe
    if not @message.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'message'
      return
    end
	
	@message.subscribers.delete(@logged_user)

    flash[:flash_success] = "Successfully unsubscribed from message"
    redirect_back_or_default :controller => 'message', :action => 'view', :id => @message.id
  end

private

   def obtain_message
     begin
        @message = ProjectMessage.find(params[:id])
     rescue ActiveRecord::RecordNotFound
       flash[:flash_error] = "Invalid message"
       redirect_back_or_default :controller => 'message'
       return false
     end
     
     return true
   end  
end
