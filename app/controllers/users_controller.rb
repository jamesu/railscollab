#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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

class UsersController < ApplicationController

  layout 'administration'
  
  before_action :process_session
  before_action :obtain_user, :except => [:index, :create, :new]
  after_action :user_track, :only => [:index, :show]

  def index
    respond_to do |format|
      format.html {
        redirect_to companies_path
      }
      format.xml  {
        if @logged_user.is_admin
          @users = User.all
          render :xml => @users.to_xml(:root => 'user')
        else
          return error_status(true, :insufficient_permissions)
        end
      }
    end
  end

  def new
    authorize! :create_user, current_user

    @user = User.new
    @company = @logged_user.company
    @permissions = Person.permission_names()

    @send_email = params[:new_account_notification] == 'false' ? false : true
    @permissions = Person.permission_names()
    @projects = @active_projects
    
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
    
    respond_to do |format|
      format.html {}
      format.xml  { 
        render :xml => @user.to_xml(:root => 'user')
      }
    end
  end
  
  def create
    authorize! :create_user, current_user

    @user = User.new
    @company = @logged_user.company
    @permissions = Person.permission_names()

    @send_email = params[:new_account_notification] == 'false' ? false : true
    @permissions = Person.permission_names()
    @projects = @active_projects
    
    user_attribs = user_params

    # Process extra parameters

    @user.username = user_attribs[:username]
    new_account_password = nil

    if user_attribs.has_key?(:generate_password)
      @user.password = @user.password_confirmation = Base64.encode64(Digest::SHA1.digest("#{rand(1 << 64)}/#{Time.now.to_f}/#{@user.username}"))[0..7]
    else
      unless user_attribs[:password].blank?
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

    # Process core parameters

    @user.attributes = user_attribs
    @user.created_by = @logged_user

    # Send it off
    saved = @user.save
    if saved
      # Time to update permissions
      update_project_permissions(@user, params[:user_project], params[:project_permission])
      # ... and send details!
      Notifier.deliver_account_new_info(@user, new_account_password) if @send_email
    end
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_user)
          redirect_back_or_default :controller => 'administration', :action => 'people'
        }
        
        format.xml  { render :xml => @user.to_xml(:root => 'user'), :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :update_profile, @user
  end
  
  def update
    authorize! :update_profile, @user
  	
    @projects = @active_projects
    @permissions = Person.permission_names()
    
    user_params = user_params

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

    unless user_params[:password].blank?
      @user.password = user_params[:password]
      @user.password_confirmation = user_params[:password_confirmation]
    end

    # Process core parameters

    @user.attributes = user_params

    # Send it off
    saved = @user.save
    if saved
      # Re-create ImValues for user
      ActiveRecord::Base.connection.execute("DELETE FROM user_im_values WHERE user_id = #{@user.id}")
      real_im_values.each do |im_value|
        im_value.save
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_updated_profile)
          redirect_back_or_default :controller => 'administration', :action => 'people'
        }
        
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def current
    @user = @logged_user
    authorize! :update_profile, @user

    render :action => 'edit'
  end

  def destroy
    authorize! :delete, @user
    
    old_name = @user.display_name
    #@user.updated_by = @logged_user
    @user.destroy
    
    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_user, {:name => old_name})
        redirect_back_or_default :controller => 'administration', :action => 'people'
      }
      
      format.xml  { head :ok }
    end
  end

  def avatar
    authorize! :update_profile, @user
    
    case request.request_method_symbol
    when :put
      user_attribs = user_params

      new_avatar = user_attribs[:avatar]
      @user.errors.add(:avatar, 'Required') if new_avatar.nil?
      @user.avatar = new_avatar

      if @user.errors.empty?
        if @user.save
          error_status(false, :success_updated_avatar)
        else
          error_status(true, :error_updating_avatar)
        end
        
        redirect_to edit_user_path(:id => @user.id)
      else
        render 'edit'
      end
    when :delete
      @user.avatar = nil
      @user.save

      error_status(false, :success_deleted_avatar)
      redirect_to edit_user_path(:id => @user.id)
    end
  end

  def show
    authorize! :show, @user
    
    respond_to do |format|
      format.html { }
      
      format.xml  {
        if @user.is_admin
          render :xml => @user.to_xml
        else
          attribs = [:id,
                     :company_id,
                     :avatar_file_name,
                     :display-name,
                     :email,
                     :fax,
                     :home_number,
                     :mobile_number,
                     :office_number,
                     :office_number_ext,
                     :time_zone,
                     :title]
          render :xml => @user.to_xml(:only => attribs)
        end  
      }
    end
  end

  def permissions
    authorize! :update_profile, @user

    @projects = @user.company.projects
    @permissions = Person.permission_names()

    case request.request_method_symbol
    when :put
      update_project_permissions(@user, params[:user_project], params[:project_permission], @projects)
      #Activity.new_log(@project, @logged_user, :edit, true)
      error_status(false, :success_updated_permissions)
    end
  end

  private
  
  def update_project_permissions(user, project_ids, project_permission, old_projects = nil)
    project_ids ||= []

    # Grab the list of project id's specified
    project_list = Project.where(:id => project_ids & user.project_ids)

    # Associate project permissions with user
    project_list.each do |project|
      permission_list = project_permission.nil? ? nil : project_permission[project.id.to_s]

      # Find permission list
      person = project.people.find_or_create_by_user_id user.id

      # Reset and update permissions
      person.reset_permissions
      person.update_str permission_list unless permission_list.nil?
      person.save
    end

    unless old_projects.nil?
    # Delete all permissions that aren't in the project list
      delete_list = old_projects.collect do |project|
        project.id unless project_list.include?(project)
      end.compact

      unless delete_list.empty?
        Person.where(:user_id => user.id, :project_id => delete_list).delete_all
      end
    end
  end

protected

  def user_params
    params[:user].nil? ? {} : params[:user].permit(:display_name, :email, :time_zone, :title, :office_number, :office_number_ext, :fax_number, :mobile_number, :home_number, :new_account_notification)
  end

  def obtain_user
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_user)
      redirect_back_or_default :controller => 'dashboard'
      return false
    end

    true
  end
end
