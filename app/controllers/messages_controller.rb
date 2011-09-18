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
      @category = @active_project.categories.find(params[:category_id])
    rescue
      @category = nil
    end
    
    unless @category.nil?
      authorize! :show, @category
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
        @page = 1 unless @page > 0
        @messages = @active_project.messages.where(msg_conditions)
                                                    .paginate(:page => @page, :per_page => Rails.configuration.messages_per_page)
        
        @pagination = []
        @messages.total_pages.times {|page| @pagination << page+1}
        
        # Important messages (html only)
        important_conditions = {'is_important' => true}
        important_conditions['category_id'] = @category.id unless @category.nil?
        important_conditions['is_private'] = false unless @logged_user.member_of_owner?
        @important_messages = @active_project.messages.where(important_conditions)

        render :template => 'messages/index'
      }
      format.xml  { 
        @messages = @active_project.messages.where(msg_conditions)
                                                    .offset(params[:offset])
                                                    .limit(params[:limit] || Rails.configuration.messages_per_page)
        render :xml => @messages.to_xml(:root => 'messages')
      }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    authorize! :show, @message
    
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
    authorize! :create_message, @active_project
    
    @message = @active_project.messages.build()
    
    # Set milestone
    @message.milestone_id = @milestone.id if @milestone
    
    # Grab default category
    begin
      @category = @active_project.categories.find(params[:category_id])
    rescue ActiveRecord::RecordNotFound
      @category = nil
    end

    if @category
      @message.category_id = @category.id
    else
      @category = @active_project.categories.where(['name = ?', Rails.configuration.default_project_message_category]).first
    end

    @message.comments_enabled = true unless (params[:message] and params[:message].has_key?(:comments_enabled))
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @message.to_xml(:root => 'message') }
    end
  end

  # GET /messages/1/edit
  def edit
    authorize! :edit, @message
  end

  # POST /messages
  # POST /messages.xml
  def create
    authorize! :create_message, @active_project
    
    @message = @active_project.messages.build(params[:message])
    
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

          number_of_users = Person.count(['user_id = ? AND project_id = ?', real_id, @active_project.id])
          next if number_of_users == 0

          real_id
        end.compact
        
        User.find(valid_users).each do |user|
          @message.ensure_subscribed(user)
          @message.send_notification(user)
        end
      end

      # Subscribe
      @message.ensure_subscribed(@logged_user) if @message.class == Message
      
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
    authorize! :edit, @message
    
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
    authorize! :delete, @message
    
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
    authorize! :show, @message

    @message.ensure_subscribed(@logged_user) if @message.class == Message

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
    authorize! :show, @message

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
        @message = @active_project.messages.find(params[:id])
     rescue ActiveRecord::RecordNotFound
       error_status(true, :invalid_message)
       redirect_back_or_default messages_path
       return false
     end
     
     return true
  end

end
