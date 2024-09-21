class Api::TaskListsController < ApplicationController

  # GET /api/v1/projects/:project_id/task_lists
  def index
    render json: { task_lists: @task_lists }, status: :ok
  end

  # GET /api/v1/projects/:project_id/task_lists/:id
  def show
    authorize! :show, @task_list

    render json: { task_list: @task_list }, status: :ok
  end

  # POST /api/v1/projects/task_lists
  def create
    authorize! :create_task_list, @active_project

    @task_list = @active_project.task_lists.build(task_list_params)
    @task_list.created_by = @logged_user
    
    if @task_list.save
      render json: project, status: :created
    else
      render json: { errors: @task_list.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/task_lists/:id
  # PATCH /api/v1/projects/:project_id/task_lists/:id
  def update
    authorize! :edit, @task_list

    @task_list.attributes = task_list_params
    @task_list.updated_by = @logged_user

    if @task_list.save
      render json: project, status: :ok
    else
      render json: { errors: @task_list.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/task_lists/:id
  def destroy
    authorize! :delete, @task_list

    @task_list.destroy
    @task_list.updated_by = @logged_user
    render json: {}, status: :ok
  end

  def task_list_params
    params.require(:task_list).permit(:name, :priority, :description, :milestone_id, :is_private, :tags)
  end

protected

  def load_related_object
    @task_list = @active_project.task_lists.find(params[:id])
  end

  def load_related_object_index
    task_conditions = {}
    task_conditions["is_private"] = false unless @logged_user.member_of_owner?

    @task_lists = @active_project.task_lists.where(task_conditions).all
  end

end
