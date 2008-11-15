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

class UserController < ApplicationController

  layout 'dashboard'

  filter_parameter_logging :password

  verify :method      => :post,
         :only        => [ :delete ],
         :add_flash   => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'project' }

  before_filter :process_session
  after_filter :user_track, :only => [:index, :card]
  after_filter :reload_owner

  def index
  	render :text => 'Hahaha!'
  end

  def add
    unless User.can_be_created_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
    end

    @user = User.new
    @company = @logged_user.company

    @send_email = params[:new_account_notification] == 'false' ? false : true
    @permissions = ProjectUser.permission_names()
    @projects = @active_projects

    case request.method
    when :get
      begin
        if @logged_user.member_of_owner? and !params[:company_id].nil?
          @company = Company.find(params[:company_id])
        end
      rescue ActiveRecord::RecordNotFound
        error_status(true, :invalid_company)
        redirect_back_or_default :controller => 'dashboard'
        return
      end

      @user.company_id = @company.id
      @user.time_zone = @company.time_zone

    when :post
      user_attribs = params[:user]

      # Process credentials

      user_credentials = params[:credentials]
      unless user_credentials[:password]
        @user.errors.add(:password, 'Required')
      else
        unless user_credentials[:password] == user_credentials[:password_confirmation]
          @user.errors.add(:password_confirmation, 'Does not match')
        end
      end

      return unless @user.errors.empty?

      # Process extra parameters

      @user.username = user_attribs[:username]
      new_account_password = nil

      if user_credentials.has_key?(:generate_password)
        @user.password = Base64.encode64(Digest::SHA1.digest("#{rand(1<<64)}/#{Time.now.to_f}/#{@user.username}"))[0..7]
      else
        new_account_password = user_credentials[:password]
        @user.password = new_account_password
      end

      if @logged_user.member_of_owner?
        @user.company_id = user_attribs[:company_id]
        unless @user.company.id == Company.owner.id
          @user.is_admin = user_attribs[:is_admin]
          @user.auto_assign = user_attribs[:auto_assign]
        end
      else
        @user.company_id = @company.id
      end

      if user_attribs[:identity_url]
        @user.identity_url = user_attribs[:identity_url]
      end

      # Process core parameters

      @user.attributes = user_attribs
      @user.created_by = @logged_user

      # Send it off

      if @user.save
        # Time to update permissions
        user_project = params[:user_project] || []

        # Grab the list of project id's specified
        project_list = user_project.select do |project_id|
          begin
            project = Project.find(project_id)
            project.can_be_managed_by(@logged_user) ? project_id : nil
          rescue ActiveRecord::RecordNotFound
            nil
          end
        end.compact

        # Associate project permissions with user
        project_permission = params[:project_permission]
        project_list.each do |project_id|
          permission_list = project_permission.nil? ? nil : project_permission[project_id]

          # Insert into permission list
          Project.find(project_id).users << @user

          # Reset and update permissions
          if permission_list.nil?
            ProjectUser.update_all(ProjectUser.update_str({}, @user), ['user_id = ? AND project_id = ?', @user.id, project_id])
          else
            ProjectUser.update_all(ProjectUser.update_str(permission_list, @user), ['user_id = ? AND project_id = ?', @user.id, project_id])
          end
        end

        #ApplicationLog.new_log(@user, @logged_user, :add, true)
        @user.send_new_account_info(new_account_password) if @send_email

        error_status(false, :success_added_user)
        redirect_back_or_default :controller => 'company', :action => 'view_client', :id => @company.id
      end
    end
  end

  def edit
    # Note: doesn't seem to have been implemented in ActiveCollab
    error_status(true, :unimplemented)
    redirect_back_or_default :controller => 'dashboard'
  end

  def delete
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_user)
      redirect_back_or_default :controller => 'dashboard'
      return
    end

    unless @user.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
    end

    old_id = @user.company_id
    old_name = @user.display_name

    @user.destroy

    error_status(false, :success_deleted_user, {:name => old_name})

    redirect_back_or_default :controller => 'company', :action => 'view', :id => old_id
  end

  def card
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(false, :invalid_user)
      redirect_back_or_default :controller => 'dashboard'
      return
    end

    unless @user.can_be_viewed_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
    end
  end
end
