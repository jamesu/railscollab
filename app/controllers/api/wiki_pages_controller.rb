class Api::WikiPagesController < ApplicationController

  # GET /api/v1/projects/:project_id/wiki_pages
  def index
    render json: { wiki_pages: @wiki_pages }, status: :ok
  end

  # GET /api/v1/projects/:project_id/wiki_pages/:id
  def show
    authorize! :show, @wiki_page

    render json: { wiki_page: @wiki_page }, status: :ok
  end

  # POST /api/v1/projects/wiki_pages
  def create
    authorize! :create_wiki_page, @active_project

    @wiki_page = @active_project.wiki_pages.build(wiki_page_params)
    @wiki_page.created_by = @logged_user
    
    if @wiki_page.save
      render json: { wiki_page: @wiki_page }, status: :created
    else
      render json: { errors: @wiki_page.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/wiki_pages/:id
  # PATCH /api/v1/projects/:project_id/wiki_pages/:id
  def update
    authorize! :edit, @wiki_page

    @wiki_page.attributes = wiki_page_params
    @wiki_page.updated_by = @logged_user

    if @wiki_page.save
      render json: { wiki_page: @wiki_page }, status: :ok
    else
      render json: { errors: @wiki_page.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/wiki_pages/:id
  def destroy
    authorize! :delete, @wiki_page

    @wiki_page.destroy
    @wiki_page.updated_by = @logged_user
    render json: {}, status: :ok
  end

  def wiki_page_params
    params.require(:wiki_page).permit(:main, :title, :content)
  end

protected

  def load_related_object
    @wiki_page = wiki_pages
              .where("slug = ? OR id = ?", params[:id], params[:id])
              .order(revision_number: :desc)
              .first
  end

  def load_related_object_index
    @wiki_pages = @active_project.wiki_pages.all
  end
end
