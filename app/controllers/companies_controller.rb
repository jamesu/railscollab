#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
# Portions Copyright (C) René Scheibe
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

class CompaniesController < ApplicationController

  layout 'administration'

  before_filter :process_session
  before_filter :obtain_company, :except => [:index, :create, :new]
  after_filter  :user_track, :only => [:card]
  after_filter  :reload_owner

  def show
    return error_status(true, :insufficient_permissions) unless (@company.can_be_seen_by(@logged_user))
    
    respond_to do |format|
      format.html { }
      format.js {}
      format.xml  {
        render :xml => @company.to_xml 
      }
    end
  end

  def index
    respond_to do |format|
      format.html {
        redirect_to :controller => 'administration', :action => 'people'
      }
      format.xml  {
        if @logged_user.is_admin
          @companies = Company.find(:all)
          render :xml => @users.to_xml(:root => 'user')
        else
          return error_status(true, :insufficient_permissions)
        end
      }
    end
  end

  def new
    return error_status(true, :insufficient_permissions) unless (Company.can_be_created_by(@logged_user))
    
    @company = Company.new
  end

  def create
    return error_status(true, :insufficient_permissions) unless (Company.can_be_created_by(@logged_user))

    @company = Company.new

    @company.attributes = params[:company]
    @company.client_of = Company.owner
    @company.created_by = @logged_user

    respond_to do |format|
      if @company.save
        format.html {
          error_status(false, :success_added_client)
          redirect_back_or_default :controller => 'administration', :action => 'people'
        }
        format.js {}
        format.xml  { render :xml => @company.to_xml(:root => 'company'), :status => :created, :location => @company }
      else
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    return error_status(true, :insufficient_permissions) unless (@company.can_be_edited_by(@logged_user))
  end
  
  def update
    return error_status(true, :insufficient_permissions) unless (@company.can_be_edited_by(@logged_user))

    @company.attributes = params[:company]
    @company.updated_by = @logged_user

    respond_to do |format|
      if @company.save
        format.html {
          error_status(false, :success_edited_client)
          redirect_back_or_default :controller => 'administration', :action => 'people'
        }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    return error_status(true, :insufficient_permissions) unless (@company.can_be_deleted_by(@logged_user))

    estatus = :success_deleted_client
  	begin
      @company.destroy
  	rescue
      estatus = :error_deleting_client
  	end

    respond_to do |format|
      format.html {
        error_status(false, estatus)
        redirect_back_or_default :controller => 'administration', :action => 'people'
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

  def permissions
    return error_status(true, :insufficient_permissions) unless (@company.can_be_managed_by(@logged_user))

  	@projects = Project.all(:order => 'name')
  	if @projects.empty?
      error_status(true, :no_projects)
      redirect_back_or_default :controller => 'administration', :action => 'people'
      return
  	end

    case request.method
    when :put
      project_list = params[:project]
      project_list ||= []
      project_ids = project_list.collect{ |ids| ids.to_i }

      # Add and remove project associations
      @projects.each do |project|
        next unless @logged_user.member_of(project)

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

  def logo
    return error_status(true, :insufficient_permissions) unless (@company.can_be_edited_by(@logged_user))
    
    case request.method
    when :put
      company_attribs = params[:company]

      new_logo = company_attribs[:logo]
      @company.errors.add(:logo, 'Required') if new_logo.nil?
      @company.logo = new_logo

      return unless @company.errors.empty?

      if @company.save
        error_status(false, :success_updated_logo)
      else
        error_status(true, :error_uploading_logo)
      end
      
      redirect_to edit_company_path(:id => @company.id)
      
    when :delete
      @company.logo = nil
      @company.save

      error_status(false, :success_deleted_logo)
      redirect_to edit_company_path(:id => @company.id)
    end
  end

  private

  def obtain_company
    begin
      @company = Company.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_company)
      redirect_back_or_default :controller => 'dashboard'
      return false
    end

    true
  end
end
