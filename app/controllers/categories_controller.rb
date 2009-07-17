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

class CategoriesController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /lists
  # GET /lists.xml
  def index
    @categories = @active_project.project_message_categories
    
    respond_to do |format|
      format.html {}
      format.xml  {
        render :xml => @categories.to_xml(:root => 'categories')
      }
    end
  end

  # GET /lists/1
  # GET /lists/1.xml
  def show
    begin
      @category = @active_project.project_message_categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end
    
    return error_status(true, :insufficient_permissions) unless @category.can_be_seen_by(@logged_user)
    
    respond_to do |format|
      format.html {
        @content_for_sidebar = 'messages/index_sidebar'
      }
      format.xml  { 
        render :xml => @category.to_xml
      }
    end
  end

  # GET /lists/new
  # GET /lists/new.xml
  def new
    return error_status(true, :insufficient_permissions) unless (ProjectMessageCategory.can_be_created_by(@logged_user, @active_project))
    
    @category = @active_project.project_message_categories.build()
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category.to_xml(:root => 'category') }
    end
  end

  # GET /lists/1/edit
  def edit
    begin
      @category = @active_project.project_message_categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return error_status(true, :invalid_message_category)
    end
    
    return error_status(true, :insufficient_permissions) unless @category.can_be_edited_by(@logged_user)
  end

  # POST /lists
  # POST /lists.xml
  def create
    return error_status(true, :insufficient_permissions) unless (ProjectMessageCategory.can_be_created_by(@logged_user, @active_project))
    
    @category = @active_project.project_message_categories.build(params[:category])

    respond_to do |format|
      if @category.save
        format.html {
          error_status(false, :success_added_message_category)
          redirect_back_or_default(@category)
        }
        format.js {}
        format.xml  { render :xml => @category.to_xml(:root => 'category'), :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lists/1
  # PUT /lists/1.xml
  def update
    begin
      @category = @active_project.project_message_categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end
    
    return error_status(true, :insufficient_permissions) unless (@category.can_be_edited_by(@logged_user))

    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.html {
          error_status(false, :success_edited_message_category)
          redirect_back_or_default(@category)
        }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lists/1
  # DELETE /lists/1.xml
  def destroy
    begin
      @category = @active_project.project_message_categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end
    
    return error_status(true, :insufficient_permissions) unless (@category.can_be_deleted_by(@logged_user))
    
    @category.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message_category)
        redirect_back_or_default(categories_url)
      }
      format.js {}
      format.xml  { head :ok }
    end
  end
  
  
  # /categories/1/posts.xml
  def posts
    begin
      @category = @active_project.project_message_categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end
    
    return error_status(true, :insufficient_permissions) unless @category.can_be_seen_by(@logged_user)
    
    include_private = @logged_user.member_of_owner?
    
    # conditions
    msg_conditions = {}
    msg_conditions['is_private'] = false unless @logged_user.member_of_owner?
    
    respond_to do |format|
      format.html {
        @content_for_sidebar = 'messages/index_sidebar'
    
        @page = params[:page].to_i
        @page = 0 unless @page > 0
        
        @messages = @category.project_messages.find(:all, 
                                                    :conditions => msg_conditions, 
                                                    :page => {:size => AppConfig.messages_per_page, :current => @page})
        
        @pagination = []
        @messages.page_count.times {|page| @pagination << page+1}
        
        # Important messages (html only)
        important_conditions = {'is_important' => true}
        important_conditions['is_private'] = false unless @logged_user.member_of_owner?
        @important_messages = @active_project.project_messages.find(:all, :conditions => important_conditions)

        render :template => 'messages/index'
      }
      format.xml  { 
        @messages = @category.project_messages.find(:all, 
                                                    :conditions => msg_conditions, 
                                                    :offset => params[:offset],
                                                    :limit => params[:limit] || AppConfig.messages_per_page)
        
        render :xml => @messages.to_xml(:only => [:id,
                                                  :title,
                                                  :created_by_id, 
                                                  :created_on,
                                                  :updated_on,
                                                  :is_private,
                                                  :is_important,
                                                  :milestone_id,
                                                  :attached_files_count, 
                                                  :comments_enabled], :root => 'messages')
      }
    end
  end
  
end
