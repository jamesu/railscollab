#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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
    respond_to do |format|
      format.html {
        when_fragment_expired "user#{@logged_user.id}_#{@project.id}_dblog", Time.now.utc + (60 * Rails.configuration.x.railscollab.minutes_to_activity_log_expire) do
          @project_log_entries = (@logged_user.member_of_owner? ? @project.activities : @project.activities.is_public)[0..(Rails.configuration.x.railscollab.project_logs_per_page-1)]
        end

        @time_now = Time.zone.now
        @late_milestones = @project.milestones.late
        @late_milstones = @late_milestones.is_public unless @logged_user.member_of_owner?
        @upcoming_milestones = Milestone.all_assigned_to(@logged_user, nil, @time_now.utc.to_date, (@time_now.utc + 14.days).to_date, [@project])

        @calendar_milestones = @upcoming_milestones.group_by do |obj| 
          date = obj.due_date.to_date
          "#{date.month}-#{date.day}"
        end

        @project_companies = @project.companies
        @important_messages = @project.messages.important
        @important_messages = @important_messages.is_public unless @logged_user.member_of_owner?
        @important_files = @project.project_files.important
        @important_files = @important_files.is_public unless @logged_user.member_of_owner?

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

      @search_results, @total_search_results = @project.search(@last_search, !@logged_user.member_of_owner?, {:page => current_page, :per_page => Rails.configuration.x.railscollab.search_results_per_page})

      @tag_names, @total_search_tags = @project.search(@last_search, !@logged_user.member_of_owner?, {}, true)
      @pagination = []
      @start_search_results = Rails.configuration.x.railscollab.search_results_per_page * (current_page-1)
      (@total_search_results.to_f / Rails.configuration.x.railscollab.search_results_per_page).ceil.times {|page| @pagination << page+1}
    else
      @last_search = I18n.t('search_box_default')
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
    authorize! :show, @project

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
    authorize! :manage, @project

    case request.request_method_symbol
    when :get
      @people = @project.users
      @user_projects = @logged_user.projects

      @companies = [Company.owner]
      @permissions = Person.permission_names()
      clients = Company.owner.clients
      if clients.length > 0
        @companies += clients
      end
    when :post, :put
      # Sort out changes to the company set
      @project.companies.clear
      @project.companies << Company.owner
      if params[:project_company]
        valid_companies = Company.where(:id => params[:project_company]).select('id')
        valid_companies.each{ |valid_company| @project.companies << valid_company unless valid_company.is_owner? }
      end

      valid_user_ids = params[:people] || []

      # Grab the old user set
      people = @project.people.all :include => {:user => :company}

      # Destroy the Person entry for each non-active user
      people.each do |person|
        user = person.user
        next if user.owner_of_owner?

        # Have a look to see if it is on our list
        has_valid_user = valid_user_ids.include? user.id.to_s
        # Have another look to see if his company is enabled
        has_valid_company = valid_companies.include? user.company

        if has_valid_user and has_valid_company
          permissions = params[:people_permissions] ? params[:people_permissions][user.id.to_s] : nil
          person.reset_permissions
          person.update_str permissions unless permissions.nil?
          person.ensure_permissions if person.user.member_of_owner?
          person.save
        else
          # Exterminate! (maybe better if this was a single query?)
          person.destroy
        end
        valid_user_ids.delete user.id.to_s if has_valid_user

        # Also check if he is activated
        #
      end

      # Create new Person entries for new users

      users = User.where(:id => valid_user_ids).includes(:company)
      users.each do |user|
        next unless valid_companies.include? user.company
        person = @project.people.create(:user => user)
        permissions = params[:people_permissions] ? params[:people_permissions][id] : nil
        person.reset_permissions
        person.update_str permissions unless permissions.nil?
        person.ensure_permissions if person.user.member_of_owner?
        person.save
      end

      # Now we can do the log keeping!
      #@project.updated_by = @logged_user

      error_status(false, :success_updated_permissions)
      redirect_to people_project_path(:id => @project.id)
    end
  end

  def users
    authorize! :manage, @project

    case request.request_method_symbol
    when :delete
      user = User.find(params[:user_id])
      unless user.owner_of_owner?
        Person.where(['user_id = ? AND project_id = ?', params[:user], @project.id]).delete_all
      end
    end

    respond_to do |format|
      format.html { redirect_back_or_default people_project_path(:id => @project.id) }
      format.xml  { render :xml => :ok }
    end
  end

  def companies
    authorize! :manage, @project

    case request.request_method_symbol
    when :delete
      company = Company.find(params[:company_id])
      unless company.is_owner?
        company_user_ids = company.users.collect{ |user| user.id }
        Person.where({ :user_id => company_user_ids, :project_id => @project.id }).delete_all
        @project.companies.delete(company)
      end
    end
    
    respond_to do |format|
      format.html { redirect_back_or_default people_project_path(:id => @project.id) }
      format.xml  { render :xml => :ok }
    end
  end

  def new
    authorize! :create_project, current_user

    @project = Project.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project.to_xml(:root => 'project') }
    end
  end

  def create
    authorize! :create_project, current_user

    @project = Project.new
    
    project_attribs = project_params

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
      Rails.configuration.x.railscollab.default_project_folders.each do |folder_name|
        folder = Folder.new(:name => folder_name)
        folder.project = @project
        folder.save
      end

      # Add default message categories
      Rails.configuration.x.railscollab.default_project_message_categories.each do |category_name|
        category = Category.new(:name => category_name)
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
        
        format.xml  { render :xml => @project.to_xml(:root => 'project'), :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :edit, @project
  end

  def update
    authorize! :edit, @project

    @project.attributes = project_params
    @project.updated_by = @logged_user
    
    respond_to do |format|
      if @project.save
        format.html {
          error_status(false, :success_edited_project)
          redirect_back_or_default(@project)
        }
        
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :delete, @project

    @project.updated_by = @logged_user
    @project.destroy
    
    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_project)
        redirect_back_or_default(:controller => 'dashboard')
      }
      
      format.xml  { head :ok }
    end
  end

  def complete
    authorize! :change_status, @project
    return error_status(true, :project_already_completed) unless @project.is_active?

    @project.set_completed(true, @logged_user)
    saved = @project.save
    
    respond_to do |format|
      format.html {
        error_status(false, :error_saving) unless saved
        redirect_back_or_default :controller => 'administration', :action => 'projects'
      }
      
      format.xml  { head :ok }
    end
  end

  def open
    authorize! :change_status, @project
    return error_status(true, :project_already_open) if @project.is_active?

    @project.set_completed(false, @logged_user)
    saved = @project.save

    respond_to do |format|
      format.html {
        error_status(false, :error_saving) unless saved
        redirect_back_or_default :controller => 'administration', :action => 'projects'
      }
      
      format.xml  { head :ok }
    end
  end

protected

  def project_layout
    ['new', 'create', 'edit' 'update'].include?(action_name) ? 'administration' : 'project_website'
  end

  def project_params
    params[:project].nil? ? {} : params[:project].permit(:name, :description, :priority, :show_description_in_overview)
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
