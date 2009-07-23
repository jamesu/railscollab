#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

class CompanyController < ApplicationController

  layout 'administration'

  verify :method      => :post,
         :only        => [ :delete_client, :delete_logo, :hide_welcome_info ],
         :add_flash   => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'dashboard' }

  before_filter :process_session
  before_filter :obtain_company, :except => [:add, :hide_welcome_info, :logo]
  after_filter  :user_track, :only => [:card]
  after_filter :reload_owner

  def card
    unless @company.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
    end
  end

  def add
    unless Company.can_be_created_by(@logged_user)
      error_status(true, :insufficient_permissions)
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

        error_status(false, :success_added_client)
        redirect_back_or_default :controller => 'administration', :action => 'people'
      end
    end
  end

  def edit
    unless @company.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
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

        error_status(false, :success_edited_client)
        redirect_back_or_default :controller => 'administration', :action => 'people'
        return
      end
    end

    render :template => 'company/edit'
  end

  def delete
  	unless @company.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

  	begin
      @company.destroy
      error_status(false, :success_deleted_client)
  	rescue
      error_status(true, :error_deleting_client)
  	end

    redirect_back_or_default :controller => 'administration', :action => 'people'
  end

  def update_permissions
  	unless @company.can_be_managed_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

  	@projects = Project.all(:order => 'name')
  	if @projects.empty?
      error_status(true, :no_projects)
      redirect_back_or_default :controller => 'administration', :action => 'people'
      return
  	end

    case request.method
    when :post
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

  def edit_logo
  	unless @company.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

    case request.method
    when :post
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

      redirect_to :controller => 'company', :action => 'edit', :id => @company.id
    end
  end

  def delete_logo
  	unless @company.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

    @company.logo = nil
    @company.save

    error_status(false, :success_deleted_logo)
    redirect_to :controller => 'company', :action => 'edit', :id => @company.id
  end

  def hide_welcome_info
    begin
      owner = Company.owner

      unless owner.can_be_edited_by(@logged_user)
        error_status(true, :insufficient_permissions)
        redirect_back_or_default :controller => 'dashboard'
        return
      end

      owner.hide_welcome_info = true
      owner.save

      error_status(false, :welcome_info_hidden)
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_company)
    end

    redirect_back_or_default :controller => 'dashboard'
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
