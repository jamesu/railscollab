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

class ProjectController < ApplicationController

  layout :project_layout
  
  verify :method => :post,
  		 :only => [ :delete, :remove_user, :remove_company, :open, :complete ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'project' }
  
  before_filter :login_required
  before_filter :process_session
  before_filter :verify_project, :except => [:add]
  
  after_filter  :user_track, :only => [:index, :overview, :search, :tags, :people]
  
  
  def index
    overview
    render 'project/overview'
  end
  
  def overview
      project = @active_project
	  when_fragment_expired "user#{@logged_user.id}_#{@active_project.id}_dblog", Time.now.utc + (60 * AppConfig.minutes_to_activity_log_expire) do
		@project_log_entries = (@logged_user.member_of_owner? ? project.application_logs : project.application_logs.public)[0..(AppConfig.project_logs_per_page-1)]
	  end
	  
      @late_milestones = project.late_milestones
      @today_milestones = project.today_milestones
      @upcomming_milestones = project.upcomming_milestones
      
      @visible_forms = project.visible_forms(true)
      @project_companies = project.companies
      @important_messages = project.important_messages
      @important_files = project.important_files
      
      @content_for_sidebar = 'overview_sidebar'
  end
  
  def search
    @project = @active_project
    @search_for = params[:search_for]
    
    if @search_for.nil?
    	@search_for = "Search..."
    end
    
    @tag_names = []
    @search_results = []
    
    @content_for_sidebar = 'search_sidebar'
  end
  
  def tags
    @project = @active_project
    
    if not @project.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    @tag_list = Tag.list_by_project(@project, !@logged_user.member_of_owner?)
  end
  
  def people
    @project = @active_project
    
    if not @project.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    @project_companies = @project.companies
  end
  
  def permissions
    @project = @active_project
    
    if not @project.can_be_managed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    case request.method
      when :get
        @project_users = @project.users
        @user_projects = @logged_user.projects
        
        @companies = [Company.owner]
        @permissions = ProjectUser.permission_names()
        clients = Company.owner.clients
        if clients.length > 0
          @companies += clients
        end
      when :post
        project_attribs = params[:project]
        
        # Sort out changes to the company set
        
        if params[:project_company]
          has_owner = false
          owner_company = Company.owner
          owner_id = owner_company.id
          
          valid_companies_ids = params[:project_company].collect do |id|
            if !has_owner and id.to_i == owner_id
              has_owner = true
            end
            
            id
          end.join ', '
          
          valid_companies = Company.find(:all, :conditions => "id IN (#{valid_companies_ids})", :select => 'id')
          
          @project.companies.clear
          @project.companies << owner_company if not has_owner
          
          valid_companies.each do |valid_company|
            @project.companies << valid_company
          end
        else
          # No member companies except the owner
          @project.companies.clear
          @project.companies << Company.owner
        end
        
        # Grab a full list of companies for comparison
        
        real_companies = [Company.owner]
        clients = Company.owner.clients
        if clients.length > 0
          real_companies += clients
        end
        real_companies_ids = real_companies.collect do |company|
          company.id
        end.join ', '
        
        # Grab the user set
        
        project_users = User.find(:all, :conditions => "company_id IN (#{real_companies_ids})", :select => ['id, company_id'])
        
        # Destroy the ProjectUser entry for each non-active user
        
        project_users.each do |user|
          next if user.owner_of_owner?
          
          found_id = nil
          
          # Have a look to see if it is on our list
          if params[:project_user]
            params[:project_user].each do |id|
              if id.to_i == user.id
                found_id = id
                break
              end
            end
          end
          
          # Have another look to see if his company is enabled
          has_valid_company = false
          valid_companies.each do |company|
            if company.id == user.company_id
              has_valid_company = true
              break
            end
          end
          
          if found_id.nil? or !has_valid_company
            # Exterminate! (maybe better if this was a single query?)
            ProjectUser.delete_all("user_id = #{user.id} AND project_id = #{@project.id}")
            
            if !found_id.nil? and !has_valid_company
              params[:project_user].delete(found_id)
            end
          elsif ProjectUser.find(:all, :conditions => "user_id = #{user.id} AND project_id = #{@project.id}").length > 0
            # Re-apply permissions
            if params[:project_user_permissions] and params[:project_user_permissions][found_id]
              ProjectUser.update_all(ProjectUser.update_str(params[:project_user_permissions][found_id], user), "user_id = #{user.id} AND project_id = #{@project.id}")
            else
              ProjectUser.update_all(ProjectUser.update_str({}, user), "user_id = #{user.id} AND project_id = #{@project.id}")
            end
            
            params[:project_user].delete(found_id)
          end
          
          # Also check if he is activated
          # 
        end
        
        # Create new ProjectUser entries for new users
        
        if params[:project_user]
          params[:project_user].each do |id|
            proj_user = User.find(id.to_i)
            next if proj_user.owner_of_owner?
            
            @project.users << proj_user
            if params[:project_user_permissions] && params[:project_user_permissions][id]
              ProjectUser.update_all(ProjectUser.update_str(params[:project_user_permissions][id], user), "user_id = #{proj_user.id} AND project_id = #{@project.id}")
            else
              ProjectUser.update_all(ProjectUser.update_str({}, user), "user_id = #{proj_user.id} AND project_id = #{@project.id}")
            end
          end
        end
        
        # Now we can do the log keeping!
        #@project.updated_by = @logged_user
        
        #if @project.save
        #  flash[:flash_success] = "Error updating permissions"
        #  redirect_to :controller => 'project', :action => 'permissions'   
        #else
          flash[:flash_success] = "Successfully updated permissions"
          redirect_to :controller => 'project', :action => 'permissions'
        #end
    end 
  end
  
  def remove_user
    @project = @active_project
    
    if not @project.can_be_managed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    user = User.find(params[:user])
    if not user.owner_of_owner?
      ProjectUser.delete_all(["user_id = ? AND project_id = ?", params[:user], @project.id])
    end
    
    redirect_back_or_default :controller => 'project', :action => 'people'
  end
  
  def remove_company
    @project = @active_project
    
    if not @project.can_be_managed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    
    company = Company.find(params[:company])
    if not company.is_owner?   
      company_user_ids = company.users.collect do |user|
        "#{user.id}"
      end.join ', '
      
      ProjectUser.delete_all("user_id IN (#{company_user_ids}) AND project_id = #{@project.id}")
      @project.companies.delete(company)
    end
    
    redirect_back_or_default :controller => 'project', :action => 'people'
  end
  
  def add
    if not Project.can_be_created_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    @project = Project.new
    
    case request.method
      when :post
        project_attribs = params[:project]
        
        @project.attributes = project_attribs
        @project.created_by = @logged_user
        @project.companies << Company.owner
		
        @auto_assign_users = Company.owner.auto_assign_users
        
        if @project.save
          # Add auto assigned people (note: we assume default permissions are all access)
          @auto_assign_users.each do |user|
			@project.users << user unless (user == @logged_user)
          end
		  
          @project.users << @logged_user
          
          # Add default folders
          AppConfig.default_project_folders.each do |folder_name|
          	folder = ProjectFolder.new(:name => folder_name)
          	folder.project = @project
			
          	ApplicationLog::new_log(folder, @logged_user, :add) if folder.save
          end
		  
		  # Add default message categories
          AppConfig.default_project_message_categories.each do |category_name|
          	category = ProjectMessageCategory.new(:name => category_name)
          	category.project = @project
			
			ApplicationLog::new_log(category, @logged_user, :add) if category.save
          end
          
          flash[:flash_success] = "Successfully added project"
          redirect_to :controller => 'project', :action => 'permissions', :active_project => @project.id
        end
    end 
  end
  
  def edit
    @project = @active_project
    
    if not @project.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    case request.method
      when :post
        project_attribs = params[:project]
        
        @project.attributes = project_attribs
        @project.updated_by = @logged_user
        
        if @project.save
          flash[:flash_success] = "Successfully updated project"
          redirect_back_or_default :controller => 'project'
        end
    end     
  end
  
  def delete
    @project = @active_project
    
    if not @project.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    @project.updated_by = @logged_user
    @project.destroy
    
    flash[:flash_success] = "Successfully deleted project"
    redirect_back_or_default :controller => 'dashboard'
  end
  
  def complete
    @project = @active_project
    
    if not @project.status_can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'administration', :action => 'projects'
      return
    end
    
    if not @project.completed_by.nil?
      flash[:flash_error] = "Project already completed"
      redirect_back_or_default :controller => 'administration', :action => 'projects'
      return
    end
    
    @project.set_completed(true, @logged_user)
    
    unless @project.save
      flash[:flash_error] = "Error saving"
    end
    
    redirect_back_or_default :controller => 'administration', :action => 'projects'
  end
  
  def open
    @project = @active_project
    
    if not @project.status_can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'administration', :action => 'projects'
      return
    end
    
    if @project.completed_by.nil?
      flash[:flash_error] = "Project already open"
      redirect_back_or_default :controller => 'administration', :action => 'projects'
      return
    end
    
    @project.set_completed(false, @logged_user)
    
    unless @project.save
      flash[:flash_error] = "Error saving"
    end
    
    redirect_back_or_default :controller => 'administration', :action => 'projects'
  end
  
protected
  
  def project_layout
    ['add', 'edit'].include?(action_name)?  'administration':'project_website'
  end
  
end