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

  after_action :user_track, only: [:index, :search, :people]

  def index
    if can?(:manage, @logged_user.company)
      @projects = @logged_user.company.projects
    else
      @projects = @logged_user.projects
    end
    
    respond_to do |format|
      format.html { render layout: "administration" }
      format.json {
        render json: @projects.to_json
      }
    end
  end

  def show
    respond_to do |format|
      format.html {
        #when_fragment_expired "user#{@logged_user.id}_#{@project.id}_dblog", Time.now.utc + (60 * Rails.configuration.railscollab.minutes_to_activity_log_expire) do
        @project_log_entries = (@logged_user.member_of_owner? ? @project.activities : @project.activities.is_public)[0..(Rails.configuration.railscollab.project_logs_per_page - 1)]
        #end

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

        @content_for_sidebar = "overview_sidebar"
      }
      format.json {
        render json: @project.to_json
      }
    end
  end

  def search
    @current_search = params[:search_id]

    unless @current_search.nil?
      @last_search = @current_search

      current_page = params[:page].to_i
      current_page = 1 unless current_page > 0

      @search_results, @total_search_results = @project.search(@last_search, !@logged_user.member_of_owner?, { page: current_page, per_page: Rails.configuration.railscollab.search_results_per_page })

      @tag_names, @total_search_tags = @project.search(@last_search, !@logged_user.member_of_owner?, {}, true)
      @pagination = []
      @start_search_results = Rails.configuration.railscollab.search_results_per_page * (current_page - 1)
      (@total_search_results.to_f / Rails.configuration.railscollab.search_results_per_page).ceil.times { |page| @pagination << page + 1 }
    else
      @last_search = I18n.t("search_box_default")
      @search_results = []

      @tag_names = Tag.list_by_project(@project, !@logged_user.member_of_owner?, false)
    end

    respond_to do |format|
      format.html {
        @content_for_sidebar = "search_sidebar"
      }
      format.json {
        render json: [].to_json
      }
    end
  end

  def people
    authorize! :show, @project

    @project_companies = @project.companies

    respond_to do |format|
      format.html { }
      format.json {
        render json: @project_companies.to_json
      }
    end
  end

  def permissions
    authorize! :manage, @project
    @companies = company_list
    
    case request.request_method_symbol
    when :get

    when :put
      @project.perms = project_params[:perms]
      @project.company_ids = project_params[:company_ids]

      saved = @project.save

      if saved
        respond_to do |format|
          format.html {
            error_status(false, :success_updated_permissions)
            redirect_back_or_default people_project_path(id: @project.id)
          }
          format.json { render json: :ok }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("permissions_form", partial: "projects/permissions_form") }
          format.html {
          }
          format.json { render json: @project.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def users
    authorize! :manage, @project

    case request.request_method_symbol
    when :delete
      user = User.find(params[:user_id])
      unless user.owner_of_owner?
        Person.where(user_id: params[:user], project_id: @project.id).delete_all
      end
    end

    respond_to do |format|
      format.html { redirect_back_or_default people_project_path(id: @project.id) }
      format.json { render json: :ok }
    end
  end

  def companies
    authorize! :manage, @project

    case request.request_method_symbol
    when :delete
      company = Company.find(params[:company_id])
      unless company.is_instance_owner?
        company_user_ids = company.users.collect { |user| user.id }
        Person.where({ user_id: company_user_ids, project_id: @project.id }).delete_all
        @project.companies.delete(company)
      end
    end

    respond_to do |format|
      format.html { redirect_back_or_default people_project_path(id: @project.id) }
      format.json { render json: :ok }
    end
  end

  def new
    authorize! :create_project, current_user

    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project.to_json }
    end
  end

  def create
    authorize! :create_project, current_user

    @project = Project.new

    project_attribs = project_params

    @project.attributes = project_attribs
    @project.created_by = @logged_user
    @project.companies << @owner

    @auto_assign_users = @owner.auto_assign_users
    saved = @project.save

    if saved
      # Add auto assigned people (note: we assume default permissions are all access)
      @auto_assign_users.each do |user|
        @project.users << user unless (user == @logged_user)
      end

      @project.users << @logged_user

      # Add default folders
      Rails.configuration.railscollab.default_project_folders.each do |folder_name|
        folder = Folder.new(name: folder_name)
        folder.project = @project
        folder.save
      end

      # Add default message categories
      Rails.configuration.railscollab.default_project_message_categories.each do |category_name|
        category = Category.new(name: category_name)
        category.project = @project
        category.save
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_project)
          redirect_to permissions_project_path(id: @project.id)
        }

        format.json { render json: @project.to_json, status: :created, location: @project }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("project_form", partial: "projects/project_form") }
        format.html { render action: "new" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
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
          redirect_back_or_default(@project.object_url)
        }

        format.json { head :ok }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("project_form", partial: "projects/project_form") }
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
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
        redirect_back_or_default(controller: "dashboard")
      }

      format.json { head :ok }
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
        redirect_back_or_default projects_path
      }

      format.json { head :ok }
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
        redirect_back_or_default projects_path
      }

      format.json { head :ok }
    end
  end

  protected

  def project_layout
    ["new", "create", "edit" "update"].include?(action_name) ? "administration" : "project_website"
  end

  def current_tab
    case action_name
    when "people", "permissions" then :people
    when "new", "create", "edit", "update", "index" then :projects
    else :overview
    end
  end

  def current_crumb
    case action_name
    when "new", "create" then :add_project
    when "edit", "update" then :edit_project
    when "search" then :search_results
    when "show" then :overview
    else super
    end
  end

  def extra_crumbs
    case action_name
    when "new", "create", "edit", "update", "permissions" then [{ title: :projects, url: "/administration/projects" }]
    else super
    end
  end

  def page_title
    case action_name
    when "show" then I18n.t("overview")
    when "index" then I18n.t("projects")
    else super
    end
  end

  def project_params
    params.require(:project).permit(:name, :description, :priority, :show_description_in_overview, :company_ids, perms: [], company_ids: [])
  end

  def load_related_object
    begin
      @project = Project.find(params[:id])
      @active_project = @project
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_project)
      redirect_back_or_default root_path
      return false
    end

    return true
  end
end
