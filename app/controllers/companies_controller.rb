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

class CompaniesController < ApplicationController
  layout "administration"

  after_action :user_track, only: [:card]

  def show
    authorize! :show, @company

    respond_to do |format|
      format.html { }

      format.json {
        render json: @company.to_json
      }
    end
  end

  def index
    @companies = [@owner] + @owner.clients
    respond_to do |format|
      format.html
      format.json {
        if can(:manage, @owner)
          render json: @companies.to_json
        else
          return error_status(true, :insufficient_permissions)
        end
      }
    end
  end

  def new
    authorize! :create_company, current_user

    @company = Company.new
  end

  def create
    authorize! :create_company, current_user

    @company = Company.new

    @company.attributes = company_params
    @company.client_of = @owner
    @company.created_by = @logged_user

    respond_to do |format|
      if @company.save
        format.html {
          error_status(false, :success_added_client)
          redirect_back_or_default companies_path
        }

        format.json { render json: @company.to_json, status: :created, location: @company }
      else
        format.html { render action: "new" }

        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :edit, @company
  end

  def update
    authorize! :edit, @company

    @company.attributes = company_params
    @company.updated_by = @logged_user

    respond_to do |format|
      if @company.save
        format.html {
          error_status(false, :success_edited_client)
          redirect_back_or_default companies_path()
        }

        format.json { head :ok }
      else
        format.html { render action: "edit" }

        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  def hide_welcome_info
    error_status(true, :invalid_company) unless @company.is_instance_owner?
    authorize! :edit, @company

    @company.hide_welcome_info = true
    saved = @company.save

    respond_to do |format|
      format.html {
        redirect_back_or_default root_path
      }
    end
  end

  def destroy
    authorize! :delete, @company

    estatus = :success_deleted_client
    begin
      @company.destroy
    rescue
      estatus = :error_deleting_client
    end

    respond_to do |format|
      format.html {
        error_status(false, estatus)
        redirect_back_or_default companies_path
      }

      format.json { head :ok }
    end
  end

  def permissions
    authorize! :manage, @company
    @projects = @owner.owner_projects

    case request.request_method_symbol
    when :get

    when :put
      @company.perms = company_params[:perms]
      @company.project_ids = company_params[:project_ids]

      saved = @company.save

      if saved
        respond_to do |format|
          format.html {
            error_status(false, :success_updated_permissions)
            redirect_back_or_default company_path(id: @company.id)
          }
          format.json { render json: :ok }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("permissions_form", partial: "companies/permissions_form") }
          format.html {
          }
          format.json { render json: @company.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def logo
    authorize! :edit, @company

    case request.request_method_symbol
    when :put
      company_attribs = company_params

      new_logo = company_attribs[:logo]
      @company.errors.add(:logo, "Required") if new_logo.nil?
      @company.logo = new_logo

      return unless @company.errors.empty?

      if @company.save
        error_status(false, :success_updated_logo)
      else
        error_status(true, :error_uploading_logo)
      end

      redirect_to edit_company_path(id: @company.id)
    when :delete
      @company.logo = nil
      @company.save

      error_status(false, :success_deleted_logo)
      redirect_to edit_company_path(id: @company.id)
    end
  end

  private

  def page_title
    case action_name
    when "show" then I18n.t("company_card", company: @company.name)
    else super
    end
  end

  def current_tab
    :people
  end

  def current_crumb
    case action_name
    when "new", "create" then :add_client
    when "show" then @company.name
    when "edit", "update" then @company.is_instance_owner? ? :edit_company : :edit_client
    else super
    end
  end

  def extra_crumbs
    crumbs = [{ title: :people, url: companies_path }]
    crumbs << { title: @company.name, url: company_path(id: @company.id) } if action_name == "permissions"
    crumbs
  end

  def company_params
    params.require(:company).permit(:logo, :name, :time_zone, :email, :homepage, :phone_number, :fax_number, :address, :address2, :city, :state, :zipcode, :country, company_ids: [], perms: [], project_ids: [])
  end

  def load_related_object
    begin
      @company = Company.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_company, {}, false)
      redirect_back_or_default root_path
      return false
    end

    true
  end
end
