class Api::FilesController < ApplicationController

  # GET /api/v1/projects/:project_id/files
  def index
    render json: { files: @files }, status: :ok
  end

  # GET /api/v1/projects/:project_id/files/:id
  def show
    authorize! :show, @file

    render json: { file: @file }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_file, @active_project

    @file.attributes = file_params
    @file.created_by = @logged_user

    if @file.save
      render json: { file: @file }, status: :created
    else
      render json: { errors: @file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/files/:id
  # PATCH /api/v1/projects/:project_id/files/:id
  def update
    authorize! :edit, @file

    @file.attributes = file_params
    @file.updated_by = @logged_user

    if @file.save
      render json: { file: @file }, status: :ok
    else
      render json: { errors: @file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/files/:id
  def destroy
    authorize! :delete, @file

    @file.updated_by = @logged_user
    @file.destroy

    render json: { }, status: :ok
  end

protected

  def file_params
    params.require(:file).permit(:tags, :folder_id, :description, :is_private, :is_important, :comments_enabled)
  end

  def load_related_object
    @file = @active_project.project_files.find(params[:id])
  end

  def load_related_object_index
    file_conditions = { "is_visible" => true }
    file_conditions["is_private"] = false unless @logged_user.member_of_owner?
    @files = @active_project.project_files.where(file_conditions).all
  end
end
