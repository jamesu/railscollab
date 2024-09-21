class Api::TimesController < ApplicationController

  # GET /api/v1/projects/:project_id/times
  def index
    render json: { times: @time_records }, status: :ok
  end

  # GET /api/v1/projects/:project_id/times/:id
  def show
    authorize! :show, @time_record
    
    render json: { time: @time_record }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_time_record, @active_project

    @time_record.attributes = time_record_params
    @time_record.created_by = @logged_user

    if @time_record.save
      render json: { time: @time_record }, status: :created
    else
      render json: { errors: @time_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/times/:id
  # PATCH /api/v1/projects/:project_id/times/:id
  def update
    authorize! :edit, @time_record

    @time_record.attributes = time_record_params
    @time_record.updated_by = @logged_user

    if @time_record.save
      render json: { time: @time_record }, status: :ok
    else
      render json: { errors: @time_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/times/:id
  def destroy
    authorize! :delete, @time_record

    @time_record.updated_by = @logged_user
    @time_record.destroy
    render json: { }, status: :ok
  end

protected

  def time_record_params
    params.require(:time).permit(:name, :description, :done_date, :hours, :open_task_id, :assigned_to_id, :is_private, :is_billable)
  end

  def load_related_object
    @time_record = @active_project.time_records.find(params[:id])
  end

  def load_related_object_index
    @time_records = @active_project.time_records.all
  end
end
