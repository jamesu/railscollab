class Api::FoldersController < ApplicationController

  # GET /api/v1/projects/:project_id/folders
  def index
    render json: { folders: @folders }, status: :ok
  end

  # GET /api/v1/projects/:project_id/folders/:id
  def show
    authorize! :show, @folder

    render json: { folder: @folder }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_folder, @active_project

    @folder = @active_project.folders.build(folder_params)
    
    if @folder.save
      render json: { folder: @folder }, status: :created
    else
      render json: { errors: @folder.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/folders/:id
  # PATCH /api/v1/projects/:project_id/folders/:id
  def update
    authorize! :edit, @folder

    @folder.attributes = folder_params
    @folder.updated_by = @logged_user

    if @folder.save
      render json: { folder: @folder }, status: :ok
    else
      render json: { errors: @folder.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/folders/:id
  def destroy
    authorize! :delete, @folder

    @folder.updated_by = @logged_user
    @folder.destroy

    render json: {}, status: :ok
  end

protected

  def folder_params
    pparams.require(:folder).permit(:name)
  end

  def load_related_object
    @folder = @active_project.folders.find(params[:id])
  end

  def load_related_object_index
    @folders = @active_project.folders.all
  end
end
