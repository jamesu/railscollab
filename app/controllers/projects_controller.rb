#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
# Portions Copyright (C) René Scheibe
# Portions Copyright (C) Ariejan de Vroom
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

class ProjectsController < ApplicationController

  layout :project_layout

  before_filter :process_session
  before_filter :obtain_project, :except => [:index, :new, :create]
  after_filter  :user_track, :only => [:index, :search, :people]

  def index
    @projects = @logged_user.is_admin ? Project.all : @logged_user.projects
    respond_to do |format|
      format.html { render :layout => 'administration' }
      format.xml  { 
        render :xml => @projects.to_xml(:root => 'projects')
      }
    end
  end
  
  def show
    include_private = @logged_user.member_of_owner?

    respond_to do |format|
      format.html {
        when_fragment_expired "user#{@logged_user.id}_#{@project.id}_dblog", Time.now.utc + (60 * Rails.configuration.minutes_to_activity_log_expire) do
          @project_log_entries = (@logged_user.member_of_owner? ? @project.application_logs : @project.application_logs.public)[0..(Rails.configuration.project_logs_per_page-1)]
        end

        @time_now = Time.zone.now
        @late_milestones = @project.project_milestones.late(include_private)
        @upcoming_milestones = ProjectMilestone.all_assigned_to(@logged_user, nil, @time_now.utc.to_date, (@time_now.utc + 14.days).to_date, [@project])

        @calendar_milestones = @upcoming_milestones.group_by do |obj| 
          date = obj.due_date.to_date
          "#{date.month}-#{date.day}"
        end

        @project_companies = @project.companies(include_private)
        @important_messages = @project.project_messages.important(include_private)
        @important_files = @project.project_files.important(include_private)

        @content_for_sidebar = 'overview_sidebar'
      }
      format.xml  { 
        render :xml => @project.to_xml(:root => 'project')
      }
    end
  end

  def search
    @current_search = params[:search_id]

    unless @current_search.nil?
      @last_search = @current_search

      current_page = params[:page].to_i
      current_page = 1 unless current_page > 0

      @search_results, @total_search_results = @project.search(@last_search, !@logged_user.member_of_owner?, {:page => current_page, :per_page => Rails.configuration.search_results_per_page})

      @tag_names, @total_search_tags = @project.search(@last_search, !@logged_user.member_of_owner?, {}, true)
      @pagination = []
      @start_search_results = Rails.configuration.search_results_per_page * (current_page-1)
      (@total_search_results.to_f / Rails.configuration.search_results_per_page).ceil.times {|page| @pagination << page+1}
    else
      @last_search = :search_box_default.l
      @search_results = []

      @tag_names = Tag.list_by_project(@project, !@logged_user.member_of_owner?, false)
    end
    
    respond_to do |format|
      format.html {
        @content_for_sidebar = 'search_sidebar' 
      }
      format.xml {
        render :xml => [].to_xml(:root => 'results') 
      }
    end
  end

  def people
    return error_status(true, :insufficient_permissions) unless @project.can_be_seen_by(@logged_user)

    @project_companies = @project.companies

    respond_to do |format|
      format.html {
      }
      format.xml {
        render :xml => @project_companies.to_xml(:root => 'companies') 
      }
    end
  end

  def permissions
    return error_status(true, :insufficient_permissions) unless @project.can_be_managed_by(@logged_user)

    case request.method_symbol
    when :get
      @project_users = @project.users
      @user_projects = @logged_user.projects

      @companies = [Company.owner]
      @permissions = ProjectUser.permission_names()
      clients = Company.owner.clients
      if clients.length > 0
        @companies += clients
      end
    when :put
      # Sort out changes to the company set

      @project.companies.clear
      @project.companies << Company.owner
      if params[:project_company]
        valid_companies = Company.all(:conditions => { :id => params[:project_company] }, :select => 'id')
        valid_companies.each{ |valid_company| @project.companies << valid_company unless valid_company.is_owner? }
      end

      valid_user_ids = params[:project_user] || []

      # Grab the old user set
      project_users = @project.project_users.all :include => {:user => :company}

      # Destroy the ProjectUser entry for each non-active user
      project_users.each do |project_user|
        user = project_user.user
        next if user.owner_of_owner?

        # Have a look to see if it is on our list
        has_valid_user = valid_user_ids.include? user.id.to_s
        # Have another look to see if his company is enabled
        has_valid_company = valid_companies.include? user.company

        if has_valid_user and has_valid_company
          permissions = params[:project_user_permissions] ? params[:project_user_permissions][user.id.to_s] : nil
          project_user.reset_permissions
          project_user.update_str permissions unless permissions.nil?
          project_user.ensure_permissions if project_user.user.member_of_owner?
          project_user.save
        else
          # Exterminate! (maybe better if this was a single query?)
          project_user.destroy
        end
        valid_user_ids.delete user.id.to_s if has_valid_user

        # Also check if he is activated
        #
      end

      # Create new ProjectUser entries for new users

      users = User.all :conditions => {:id => valid_user_ids}, :include => :company
      users.each do |user|
        next unless valid_companies.include? user.company
        project_user = @project.project_users.create :user => user
        permissions = params[:project_user_permissions] ? params[:project_user_permissions][id] : nil
        project_user.reset_permissions
        project_user.update_str permissions unless permissions.nil?
        project_user.ensure_permissions if project_user.user.member_of_owner?
        project_user.save
      end

      # Now we can do the log keeping!
      #@project.updated_by = @logged_user

      error_status(false, :success_updated_permissions)
      redirect_to people_project_path(:id => @project.id)
    end
  end

  def users
    return error_status(true, :insufficient_permissions) unless @project.can_be_managed_by(@logged_user)

    case request.method_symbol
    when :delete
      user = User.find(params[:user_id])
      unless user.owner_of_owner?
        ProjectUser.delete_all(['user_id = ? AND project_id = ?', params[:user], @project.id])
      end
    end

    respond_to do |format|
      format.html { redirect_back_or_default people_project_path(:id => @project.id) }
      format.xml  { render :xml => :ok }
    end
  end

  def companies
    return error_status(true, :insufficient_permissions) unless @project.can_be_managed_by(@logged_user)

    case request.method_symbol
    when :delete
      company = Company.find(params[:company_id])
      unless company.is_owner?
        company_user_ids = company.users.collect{ |user| user.id }
        ProjectUser.delete_all({ :user_id => company_user_ids, :project_id => @project.id })
        @project.companies.delete(company)
      end
    end
    
    respond_to do |format|
      format.html { redirect_back_or_default people_project_path(:id => @project.id) }
      format.xml  { render :xml => :ok }
    end
  end

  def new
    return error_status(true, :insufficient_permissions) unless Project.can_be_created_by(@logged_user)

    @project = Project.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project.to_xml(:root => 'project') }
    end
  end

  def create
    return error_status(true, :insufficient_permissions) unless Project.can_be_created_by(@logged_user)

    @project = Project.new
    
    project_attribs = params[:project]

    @project.attributes = project_attribs
    @project.created_by = @logged_user
    @project.companies << Company.owner

    @auto_assign_users = Company.owner.auto_assign_users
    saved = @project.save

    if saved
      # Add auto assigned people (note: we assume default permissions are all access)
      @auto_assign_users.each do |user|
        @project.users << user unless (user == @logged_user)
      end

      @project.users << @logged_user

      # Add default folders
      Rails.configuration.default_project_folders.each do |folder_name|
        folder = ProjectFolder.new(:name => folder_name)
        folder.project = @project
        folder.save
      end

      # Add default message categories
      Rails.configuration.default_project_message_categories.each do |category_name|
        category = ProjectMessageCategory.new(:name => category_name)
        category.project = @project
        category.save
      end
    end
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_project)
          redirect_to permissions_project_path(:id => @project.id)
        }
        format.js {}
        format.xml  { render :xml => @project.to_xml(:root => 'project'), :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    return error_status(true, :insufficient_permissions) unless @project.can_be_edited_by(@logged_user)
  end

  def update
    return error_status(true, :insufficient_permissions) unless @project.can_be_edited_by(@logged_user)

    @project.attributes = params[:project]
    @project.updated_by = @logged_user
    
    respond_to do |format|
      if @project.save
        format.html {
          error_status(false, :success_edited_project)
          redirect_back_or_default(@project)
        }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    return error_status(true, :insufficient_permissions) unless @project.can_be_deleted_by(@logged_user)

    @project.updated_by = @logged_user
    @project.destroy
    
    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_project)
        redirect_back_or_default(:controller => 'dashboard')
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

  def complete
    return error_status(true, :insufficient_permissions) unless @project.status_can_be_changed_by(@logged_user)
    return error_status(true, :project_already_completed) unless @project.is_active?

    @project.set_completed(true, @logged_user)
    saved = @project.save
    
    respond_to do |format|
      format.html {
        error_status(false, :error_saving) unless saved
        redirect_back_or_default :controller => 'administration', :action => 'projects'
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

  def open
    return error_status(true, :insufficient_permissions) unless @project.status_can_be_changed_by(@logged_user)
    return error_status(true, :project_already_open) if @project.is_active?

    @project.set_completed(false, @logged_user)
    saved = @project.save

    respond_to do |format|
      format.html {
        error_status(false, :error_saving) unless saved
        redirect_back_or_default :controller => 'administration', :action => 'projects'
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

protected

  def project_layout
    ['new', 'create', 'edit' 'update'].include?(action_name) ? 'administration' : 'project_website'
  end

   def obtain_project
     begin
        @project = Project.find(params[:id])
        @active_project = @project
     rescue ActiveRecord::RecordNotFound
       error_status(true, :invalid_project)
       redirect_back_or_default :controller => 'dashboard'
       return false
     end
     
     return true
  end
end
