class Api::TasksController < ApplicationController

  # GET /api/v1/projects/:project_id/tasks
  def index
    render json: { tasks: @tasks }, status: :ok
  end

  # GET /api/v1/projects/:project_id/tasks/:id
  def show
    authorize! :show, @task

    render json: { task: @task }, status: :ok
  end

  # POST /api/v1/projects/tasks
  def create
    authorize! :create_task, @active_project

    @task = @task_list.tasks.build(task_params)
    @task.created_by = @logged_user
    
    if @task.save
      render json: project, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/tasks/:id
  # PATCH /api/v1/projects/:project_id/tasks/:id
  def update
    authorize! :edit, @task

    @task.attributes = task_params
    @task.updated_by = @logged_user

    if @task.save
      render json: project, status: :ok
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/projects/:project_id/task_lists/:id/tasks/reorder
  def reorder
    authorize! :edit, @task_list

    order = (params[:task_ids] || []).collect { |id| id.to_i }

    @task_list.tasks.each do |item|
      idx = order.index(item.id)
      item.order = idx || @task_list.tasks.length
      item.save!
    end

    render json: {}, status: :ok
  end

  # DELETE /api/v1/projects/:project_id/tasks/:id
  def destroy
    authorize! :delete, @task

    @task.destroy
    @task.updated_by = @logged_user
    render json: {}, status: :ok
  end

protected

  def task_params
    params.require(:task).permit(:completed, :text, :assigned_to_id, :task_list_id, :estimated_hours)
  end

  def grab_list
    @task_list = @active_project.task_lists.find(params[:task_list_id])
    authorize! :show, @task_list
  end

  def load_related_object
    grab_list
    @task = @task_list.tasks.find(params[:id])
  end

  def load_related_object_index
    grab_list
    @tasks = @task_list.tasks.all
  end

end
