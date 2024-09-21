# RailsCollab
# Copyright (C) 2024 James S Urquhart
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

class Api::ProjectsController < ApiController

  # GET /api/v1/projects
  def index
    render json: { projects: @projects }, status: :ok
  end

  # GET /api/v1/projects/:id
  def show
    authorize! :show, @project

    render json: { project: @project }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_project, current_user

    @project = Project.new

    @project.attributes = project_params
    @project.created_by = @logged_user
    @project.companies << @owner

    @auto_assign_users = @owner.auto_assign_users

    if @project.save
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

      render json: { project: @project }, status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:id
  # PATCH /api/v1/projects/:id
  def update
    authorize! :edit, @project
    
    @project.attributes = project_params
    @project.updated_by = @logged_user

    if @project.save
      render json: { project: @project }, status: :ok
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:id
  def destroy
    authorize! :delete, @project

    @project.updated_by = @logged_user
    @project.destroy
    render json: { }, status: :ok
  end

protected

  def project_params
    params.require(:project).permit(:name, :description, :priority, :show_description_in_overview, :company_ids, perms: [], company_ids: [])
  end

  def load_related_object
    @project = Project.find(params[:id])
    @active_project = @project
  end

  def load_related_object_index
    if can?(:manage, @logged_user.company)
      @projects = @logged_user.company.projects
    else
      @projects = @logged_user.projects
    end
  end

end
