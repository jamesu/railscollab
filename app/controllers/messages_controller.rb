#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

class MessagesController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  before_filter :obtain_message, :except => [:index, :new, :create]
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /messages
  # GET /messages.xml
  def index
    begin
      @category = @active_project.project_message_categories.find(params[:category_id])
    rescue
      @category = nil
    end
    
    unless @category.nil?
      return error_status(true, :insufficient_permissions) unless @category.can_be_seen_by(@logged_user)
    end
    
    include_private = @logged_user.member_of_owner?
    
    # conditions
    msg_conditions = {}
    msg_conditions['category_id'] = @category.id unless @category.nil?
    msg_conditions['is_private'] = false unless @logged_user.member_of_owner?

    # probably should make this more generic...
    if params[:display] == 'list'
      session[:msglist] = true
    elsif params[:display] == 'summary'
      session[:msglist] = false
    end
    @display_list = session[:msglist] || false

    respond_to do |format|
      format.html {
        @content_for_sidebar = 'index_sidebar'
    
        @page = params[:page].to_i
        @page = 0 unless @page > 0
        
        @messages = @active_project.project_messages.find(:all, 
                                                          :conditions => msg_conditions, 
                                                          :page => {:size => AppConfig.messages_per_page, :current => @page})
        
        @pagination = []
        @messages.page_count.times {|page| @pagination << page+1}
        
        # Important messages (html only)
        important_conditions = {'is_important' => true}
        important_conditions['category_id'] = @category.id unless @category.nil?
        important_conditions['is_private'] = false unless @logged_user.member_of_owner?
        @important_messages = @active_project.project_messages.find(:all, :conditions => important_conditions)

        render :template => 'messages/index'
      }
      format.xml  { 
        @messages = @active_project.project_messages.find(:all, 
                                                          :conditions => msg_conditions, 
                                                          :offset => params[:offset],
                                                          :limit => params[:limit] || AppConfig.messages_per_page)
        render :xml => @messages.to_xml(:root => 'messages')
      }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    return error_status(true, :insufficient_permissions) unless @message.can_be_seen_by(@logged_user)
    
    @private_object = @message.is_private

    @subscribers = @message.subscribers
    @content_for_sidebar = 'view_sidebar'
    
    respond_to do |format|
      format.html {}
      format.xml  { 
        render :xml => @message.to_xml(:root => 'message')
      }
    end
  end

  # GET /messages/new
  # GET /messages/new.xml
  def new
    return error_status(true, :insufficient_permissions) unless (ProjectMessage.can_be_created_by(@logged_user, @active_project))
    
    @message = @active_project.project_messages.build()
    
    # Set milestone
    @message.milestone_id = @milestone.id if @milestone
    
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
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @message.to_xml(:root => 'message') }
    end
  end

  # GET /messages/1/edit
  def edit
    return error_status(true, :insufficient_permissions) unless @message.can_be_edited_by(@logged_user)
  end

  # POST /messages
  # POST /messages.xml
  def create
    return error_status(true, :insufficient_permissions) unless (ProjectMessage.can_be_created_by(@logged_user, @active_project))
    
    @message = @active_project.project_messages.build(params[:message])
    
    message_attribs = params[:message]
    @message.attributes = message_attribs
    @message.created_by = @logged_user
    
    saved = @message.save
    estatus = :success_added_message
    
    if saved
      @message.tags = message_attribs[:tags]
      
      # Notify the subscribers
      unless params[:notify_user].nil?
        valid_users = params[:notify_user].collect do |user_id|
          real_id = user_id.to_i
          next if real_id == @logged_user.id # will be subscribed below

          number_of_users = ProjectUser.count(:conditions => ['user_id = ? AND project_id = ?', real_id, @active_project.id])
          next if number_of_users == 0

          real_id
        end.compact
        
        User.find(valid_users).each do |user|
          @message.ensure_subscribed(user)
          @message.send_notification(user)
        end
      end

      # Subscribe
      @message.ensure_subscribed(@logged_user) if @message.class == ProjectMessage
      
      # Handle uploaded files
      if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private) != params[:uploaded_files].length)
        estatus = :success_added_message_failed_attachments
        error_status(false, :success_added_message_failed_attachments)
      end
    end
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, estatus)
          redirect_back_or_default(@message)
        }
        format.js {}
        format.xml  { render :xml => @message.to_xml(:root => 'message'), :status => :created, :location => @message }
      else
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /messages/1
  # PUT /messages/1.xml
  def update
    return error_status(true, :insufficient_permissions) unless (@message.can_be_edited_by(@logged_user))
    
    message_attribs = params[:message]
    @message.attributes = message_attribs
    
    @message.updated_by = @logged_user
    @message.tags = message_attribs[:tags]

    saved = @message.save
    estatus = :success_edited_message
    
    # handle uploaded files
    if saved
      if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private) != params[:uploaded_files].length)
        estatus = :success_edited_message_failed_attachments
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, estatus)
          redirect_back_or_default(@message)
        }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    return error_status(true, :insufficient_permissions) unless (@message.can_be_deleted_by(@logged_user))
    
    @message.updated_by = @logged_user
    @message.destroy
    
    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message)
        redirect_back_or_default(messages_url(:category_id => params[:category_id]))
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

  # PUT /messages/1/subscribe
  def subscribe
    unless @message.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default messages_path
      return
    end

    @message.ensure_subscribed(@logged_user) if @message.class == ProjectMessage

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message)
        redirect_back_or_default(message_url(:id => @message.id))
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

  # PUT /messages/1/unsubscribe
  def unsubscribe
    unless @message.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default messages_path
      return
    end

  	@message.subscribers.delete(@logged_user)

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message)
        redirect_back_or_default(message_url(:id => @message.id))
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

private

   def obtain_message
     begin
        @message = @active_project.project_messages.find(params[:id])
     rescue ActiveRecord::RecordNotFound
       error_status(true, :invalid_message)
       redirect_back_or_default messages_path
       return false
     end
     
     return true
  end

end
