class Api::CategoriesController < ApplicationController

  # GET /api/v1/projects/:project_id/categories
  def index
    render json: { categories: @categories }, status: :ok
  end

  # GET /api/v1/projects/:project_id/categories/:id
  def show
    authorize! :show, @category

    render json: { category: @category }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_message_category, @active_project

    @category = @active_project.categories.build(category_params)
    
    if @category.save
      render json: { category: @category }, status: :created
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/categories/:id
  # PATCH /api/v1/projects/:project_id/categories/:id
  def update
    authorize! :edit, @category

    @category.attributes = category_params
    @category.updated_by = @logged_user

    if @category.save
      render json: { category: @category }, status: :ok
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/categories/:id
  def destroy
    authorize! :delete, @category

    @category.updated_by = @logged_user
    @category.destroy

    render json: {}, status: :ok
  end

protected

  def category_params
    params.require(:category).permit(:name)
  end

  def load_related_object
    @category = @active_project.categories.find(params[:id])
  end

  def load_related_object_index
    @categories = @active_project.categories.all
  end

end
