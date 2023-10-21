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
  layout "administration"

  after_action :user_track, only: [:index, :show]

  def index
    respond_to do |format|
      format.html {
        redirect_to companies_path
      }
      format.json {
        if @logged_user.is_admin
          @users = User.all
          render json: @users.to_json
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

    @send_email = params[:new_account_notification] == "false" ? false : true
    @permissions = Person.permission_names()
    @projects = @active_projects

    begin
      if @logged_user.member_of_owner? and !params[:company_id].nil?
        @company = Company.find(params[:company_id])
      end
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_company)
      redirect_back_or_default root_path
      return
    end

    @user.company_id = @company.id
    @user.time_zone = @company.time_zone

    respond_to do |format|
      format.html { }
      format.json {
        render json: @user.to_json
      }
    end
  end

  def create
    authorize! :create_user, current_user

    @user = User.new
    @company = @logged_user.company
    @permissions = Person.permission_names()

    @send_email = params[:new_account_notification] == "false" ? false : true
    @permissions = Person.permission_names()
    @projects = @active_projects

    user_attribs = admin_user_params

    # Process extra parameters

    @user.username = user_attribs[:username]
    new_account_password = nil

    new_account_password = @user.password

    # Process core parameters

    @user.attributes = user_attribs
    @user.created_by = @logged_user

    # Send it off
    saved = @user.save
    if saved
      # Time to update permissions
      update_project_permissions(@user, params[:user_project], params[:project_permission])
      # ... and send details!
      MailNotifier.account_new_info(@user, new_account_password).deliver_now if @send_email
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_user)
          redirect_back_or_default companies_path
        }

        format.json { render json: @user.to_json, status: :created, location: @user }
      else
        format.html { render action: "new" }

        format.json { render json: @user.errors, status: :unprocessable_entity }
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

    input_params = (@logged_user.is_admin && @logged_user.member_of_owner?) ? admin_user_params : user_params

    # Process core parameters

    @user.attributes = input_params

    # Send it off
    saved = @user.save
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_updated_profile)
          redirect_back_or_default company_people_path(@user.company)
        }

        format.json { head :ok }
      else
        format.html { render action: "edit" }

        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def current
    @user = @logged_user
    authorize! :update_profile, @user

    render action: "edit"
  end

  def destroy
    authorize! :delete, @user

    old_name = @user.display_name
    #@user.updated_by = @logged_user
    @user.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_user, { name: old_name })
        redirect_back_or_default companies_path
      }

      format.json { head :ok }
    end
  end

  def avatar
    authorize! :update_profile, @user

    case request.request_method_symbol
    when :put
      user_attribs = user_params

      new_avatar = user_attribs[:avatar]
      @user.errors.add(:avatar, "Required") if new_avatar.nil?
      @user.avatar = new_avatar

      if @user.errors.empty?
        if @user.save
          error_status(false, :success_updated_avatar)
        else
          error_status(true, :error_updating_avatar)
        end

        redirect_to edit_user_path(id: @user.id)
      else
        render "edit"
      end
    when :delete
      @user.avatar = nil
      @user.save

      error_status(false, :success_deleted_avatar)
      redirect_to edit_user_path(id: @user.id)
    end
  end

  def show
    authorize! :show, @user

    respond_to do |format|
      format.html { }

      format.json {
        if @user.is_admin
          render json: @user.to_json
        else
          attribs = [:id,
                     :company_id,
                     :avatar_file_name,
                     :display - name,
                     :email,
                     :fax,
                     :home_number,
                     :mobile_number,
                     :office_number,
                     :office_number_ext,
                     :time_zone,
                     :title]
          render json: @user.to_json(only: attribs)
        end
      }
    end
  end

  protected

  def page_title
    case action_name
    when "show" then I18n.t("user_card", user: @user.display_name)
    else super
    end
  end

  def current_crumb
    case action_name
    when "new", "create" then :add_user
    when "show" then @user.display_name
    when "edit", "update", "current" then :edit_user
    else super
    end
  end

  def extra_crumbs
    user = (@user || @logged_user)
    crumbs = [
      { title: :people, url: "/companies" },
      { title: user.company.name, url: company_path(user.company) },
    ]
    crumbs << { title: user.display_name, url: user_path(user) } if action_name == "permissions"
    crumbs
  end

  def current_tab
    :people
  end

  def user_permit_list
    return [:generate_password, :password, :password_confirmation, :display_name, :email, :time_zone, :title, :office_number, :office_number_ext, :fax_number, :mobile_number, :home_number, :new_account_notification]
  end

  def user_params
    params.require(:user).permit(*user_permit_list)
  end

  def admin_user_params
    nl = user_permit_list
    nl << :username
    nl << :company_id
    nl << :is_admin
    nl << :auto_assign
    nl << :user_project
    nl << :project_permission
    params[:user].nil? ? {} : params[:user].permit(*nl, perms: [])
  end

  def load_related_object
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_user, {}, false)
      redirect_back_or_default root_path
      return false
    end

    true
  end
end
