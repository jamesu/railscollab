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

class CompanyController < ApplicationController

  layout 'dashboard'
  
  verify :method => :post,
  		 :only => [ :delete_client, :delete_logo, :hide_welcome_info ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'dashboard' }
  
  before_filter :login_required
  before_filter :process_session
  before_filter :obtain_company, :except => [:add_client, :edit, :hide_welcome_info, :logo]
  after_filter  :user_track, :except => [:logo]
  
  # Caching
  caches_page :logo
  cache_sweeper :company_sweeper, :only => [ :edit, :edit_client, :edit_logo, :delete_client, :delete_logo ]
  
  def card    
    if not @company.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
  end
  
  def view_client    
    if not @company.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    # Little bit of a hack, nothing to worry about
    @active_projects = []
    @finished_projects = []
    
    @company.projects.each do |project|
      if project.is_active?
      	@active_projects << project
      else
      	@finished_projects << project
      end
    end
    
    @content_for_sidebar = 'dashboard/my_projects_sidebar'
  end
  
  def edit
    begin
      @company = Company.owner
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid company"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    if not @company.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    case request.method
      when :post
        company_attribs = params[:company]
        
        @company.attributes = company_attribs
        @company.updated_by = @logged_user
        if @company.save
          #ApplicationLog.new_log(@company, @logged_user, :edit, true)
          
          flash[:flash_success] = "Successfully updated company"
          redirect_back_or_default :controller => 'company', :action => 'card', :id => @company.id
        end
    end
  end
  
  def add_client
    if not Company.can_be_created_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    @company = Company.new
    
    case request.method
      when :post
        company_attribs = params[:company]
        
        @company.attributes = company_attribs
        @company.client_of = Company.owner
        @company.created_by = @logged_user
        
        if @company.save
          #ApplicationLog.new_log(@company, @logged_user, :add, true)
          
          flash[:flash_success] = "Successfully added client"
          redirect_back_or_default :controller => 'administration', :action => 'clients'
        end
    end      
  end
  
  def edit_client    
    if not @company.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    case request.method
      when :post
        company_attribs = params[:company]
        
        @company.attributes = company_attribs
        @company.updated_by = @logged_user
        
        if @company.save
          #ApplicationLog.new_log(@company, @logged_user, :edit, true)
          
          flash[:flash_success] = "Successfully updated company"
          redirect_back_or_default :controller => 'company', :action => 'card', :id => @company.id
          return
        end
    end
    
  	render 'company/edit'
  end
  
  def delete_client    
  	if not @company.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
  	end
  	
  	begin
  		@company.destroy
        #ApplicationLog.new_log(@company, @logged_user, :delete, true)
        flash[:flash_success] = "Successfully deleted client"
  	rescue
      flash[:flash_error] = "Error deleting client"
  	end
  	
    redirect_back_or_default :controller => 'administration', :action => 'clients'
  end
  
  def update_permissions
  	if not @company.can_be_managed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
  	end
  	
  	@projects = Project.find(:all, :order => 'name')
  	if @projects.length == 0
      flash[:flash_error] = "No projects"
      redirect_back_or_default :controller => 'company', :action => 'card', :id => @company.id
      return
  	end
  	
    case request.method
      when :post
      	project_list = params[:project]
      	project_list ||= []
        project_ids = project_list.collect do |ids|
        	ids.to_i
        end
        
        # Add and remove project associations
        @projects.each do |project|
        	if @logged_user.member_of(project)
	        	if project_ids.include?(project.id)
	        		begin
	        			project.companies.find(@company.id)
	        		rescue ActiveRecord::RecordNotFound
	        			project.companies << @company
	        		end
	        	else
	        		project.companies.delete(@company)
	        	end
        	end
        end
    end
  end

  def edit_logo
  	if not @company.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

    case request.method
      when :post
          company_attribs = params[:company]
          
          new_logo = company_attribs[:logo]
          if new_logo.nil?
          	@company.errors.add(:logo, 'Required')
          end
          
          @company.logo = new_logo
          
          if @company.errors.empty?
	          if @company.save
	          	flash[:flash_success] = "Successfully updated logo"
	          else
	          	flash[:flash_error] = "Error uploading logo"
	          end
	          
	          redirect_to :controller => 'company', :action => 'card', :id => @company.id 
          end
    end    
  end
  
  def delete_logo
  	if not @company.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
  	end
    
    @company.logo = nil
    @company.save
    
    flash[:flash_success] = "Successfully deleted logo"
    redirect_to :controller => 'company', :action => 'card', :id => @company.id
  end
  
  def logo
    begin
      company = Company.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Not found', :status => 404
      return
    end
    
  	# Get avatar data
  	data = FileRepo.get_data(company.logo_file)
  	
  	if data.empty?
  		render :text => 'Not found', :status => 404
  		return
  	end
  	
  	send_data data, :type => 'image/png', :disposition => 'inline'
  end
   
  def hide_welcome_info
    begin
      owner = Company.owner
      
      if not owner.can_be_edited_by(@logged_user)
        flash[:flash_error] = "Insufficient permissions"
        redirect_back_or_default :controller => 'dashboard'
        return
      end
    
      owner.hide_welcome_info = true
      owner.save
      
      flash[:flash_error] = "Welcome info hidden"
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Error hiding welcome info"
    end
    
    redirect_back_or_default :controller => 'dashboard'
  end

private

  def obtain_company
    begin
      @company = Company.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid company"
      redirect_back_or_default :controller => 'dashboard'
      return false
    end
    
    return true
  end

end
