class Api::MilestonesController < ApplicationController

  # GET /api/v1/projects/:project_id/milestones
  def index
    render json: { milestones: @milestones }, status: :ok
  end

  # GET /api/v1/projects/:project_id/milestones/:id
  def show
    authorize! :show, @milestone

    render json: { milestone: @milestone }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_milestone, @active_project

    @milestone.attributes = milestone_params
    @milestone.created_by = @logged_user

    if @milestone.save
      render json: { milestone: @milestone }, status: :created
    else
      render json: { errors: @milestone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/milestones/:id
  # PATCH /api/v1/projects/:project_id/milestones/:id
  def update
    authorize! :edit, @milestone

    @milestone.attributes = milestone_params
    @milestone.updated_by = @logged_user

    if @milestone.save
      render json: { milestone: @milestone }, status: :ok
    else
      render json: { errors: @milestone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/milestones/:id
  def destroy
    authorize! :delete, @milestone

    @milestone.updated_by = @logged_user
    @milestone.destroy
    
    render json: { @milestone: '@active_project.milestones deleted successfully' }, status: :ok
  end

protected

  def milestone_params
    params.require(:milestone).permit(:name, :description, :due_date, :assigned_to_id, :is_private)
  end

  def load_related_object
    @milestone = @active_project.milestones.find(params[:id])
  end

  def load_related_object_index
    ms_conditions = {}
    ms_conditions["is_private"] = false unless @logged_user.member_of_owner?
    @milestones = @active_project.milestones.where(ms_conditions).all
  end

end
