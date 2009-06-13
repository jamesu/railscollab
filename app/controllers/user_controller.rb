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

  def index
  	redirect_to :controller => 'administration', :action => 'people'
  end

  def add
    unless User.can_be_created_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
    end

    @user = User.new
    @company = @logged_user.company
    @permissions = ProjectUser.permission_names()

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

      # Process extra parameters

      @user.username = user_attribs[:username]
      new_account_password = nil

      if user_attribs.has_key?(:generate_password)
        @user.password = Base64.encode64(Digest::SHA1.digest("#{rand(1 << 64)}/#{Time.now.to_f}/#{@user.username}"))[0..7]
      else
        if user_attribs.has_key? :password and !user_attribs[:password].empty?
          @user.password = user_attribs[:password]
          @user.password_confirmation = user_attribs[:password_confirmation]
        end
      end
      
      new_account_password = @user.password

      if @logged_user.member_of_owner?
        @user.company_id = user_attribs[:company_id]
        if @user.member_of_owner?
          @user.is_admin = user_attribs[:is_admin]
          @user.auto_assign = user_attribs[:auto_assign]
        end
      else
        @user.company_id = @company.id
      end
      
      @user.identity_url = user_attribs[:identity_url] if user_attribs[:identity_url]

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
        
        @user.send_new_account_info(new_account_password) if @send_email

        error_status(false, :success_added_user)
        redirect_back_or_default :controller => 'administration', :action => 'people'
      end
    end
  end

  def edit
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_user)
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
  	unless @user.profile_can_be_updated_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end
  	
  	@projects = @active_projects
    @permissions = ProjectUser.permission_names()

    case request.method
    when :post
      user_params = params[:user]

      # Process IM Values
      all_im_values = user_params[:im_values] || {}
      all_im_values.reject! do |key, value|
        value[:value].strip.length == 0
      end

      if user_params[:default_im_value].nil?
        default_value = '-1'
      else
        default_value = user_params[:default_im_value]
      end

      real_im_values = all_im_values.collect do |type_id,value|
        real_im_value = value[:value]
        ImValue.new(:im_type_id => type_id.to_i, :user_id => @user.id, :value => real_im_value, :is_default => (default_value == type_id))
      end

      # Process extra parameters

      if @logged_user.is_admin?
        @user.username = user_params[:username]

        if @logged_user.member_of_owner?
          @user.company_id = user_params[:company_id] unless user_params[:company_id].nil?
          if @user.member_of_owner?
            @user.is_admin = user_params[:is_admin]
            @user.auto_assign = user_params[:auto_assign]
          end
        end
      end

      if user_params.has_key? :password and !user_params[:password].empty?
        @user.password = user_params[:password]
        @user.password_confirmation = user_params[:password_confirmation]
      end
      
      @user.identity_url = user_params[:identity_url] if user_params[:identity_url]

      # Process core parameters

      @user.attributes = user_params

      # Send it off

      if @user.save
        # Re-create ImValues for user
        ActiveRecord::Base.connection.execute("DELETE FROM user_im_values WHERE user_id = #{@user.id}")
        real_im_values.each do |im_value|
          im_value.save
        end
        error_status(false, :success_updated_profile)
        redirect_back_or_default :controller => 'administration', :action => 'people'
      end
    end
  end
  
  def current
    @user = @logged_user
    unless @user.profile_can_be_updated_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
    end
  	
  	@projects = @active_projects
    
    render :action => 'edit'
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

    redirect_back_or_default :controller => 'administration', :action => 'people'
  end
  
  def edit_avatar
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_user)
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
  	unless @user.profile_can_be_updated_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

    case request.method
    when :post
      user_attribs = params[:user]

      new_avatar = user_attribs[:avatar]
      @user.errors.add(:avatar, 'Required') if new_avatar.nil?
      @user.avatar = new_avatar

      if @user.errors.empty?
        if @user.save
          error_status(false, :success_updated_avatar)
        else
          error_status(true, :error_updating_avatar)
        end

        redirect_to :controller => 'user', :action => 'edit', :id => @user.id
      end
    end
  end

  def delete_avatar
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_user)
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
  	unless @user.profile_can_be_updated_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

    @user.avatar = nil
    @user.save

    error_status(false, :success_deleted_avatar)
    redirect_to :controller => 'user', :action => 'edit', :id => @user.id
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
