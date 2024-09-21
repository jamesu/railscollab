class Api::ProjectPeopleController < ApplicationController
  # GET /api/v1/projects/:project_id/members
  def index
    render json: { members: @people }, status: :ok
  end

  # PUT /api/v1/projects/:project_id/members
  def index_update
    ActiveRecord::Base.transaction do
      @project.people.destroy_all

      new_members = params[:members].map do |member_data|
        @project.members.build(member_data)
      end

      if new_members.all?(&:save)
        render json: { members: @project.people }, status: :ok
      else
        render json: { errors: new_members.map { |m| m.errors.full_messages }.flatten }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/projects/:project_id/members/:id
  def show
    render json: { member: @person }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_people, @active_project

    @person.attributes = people_params
    @person.created_by = @logged_user

    if @person.save
      render json: { member: @person }, status: :created
    else
      render json: { errors: @person.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/members/:id
  # PATCH /api/v1/projects/:project_id/members/:id
  def update
    authorize! :edit, @person

    @person.attributes = member_params
    @person.updated_by = @logged_user

    if @person.save
      render json: { member: @person }, status: :ok
    else
      render json: { errors: @person.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/members/:id
  def destroy
    authorize! :delete, @person

    @person.updated_by = @logged_user
    @person.destroy
    render json: { @member: '@active_project.peoples deleted successfully' }, status: :ok
  end

protected

  def member_params
    params.require(:member).permit(:name, :description, :due_date, :assigned_to_id, :is_private)
  end

  def load_related_object
    @person = @active_project.peoples.find(params[:id])
  end

  def load_related_object_index
    @people = @active_project.people.all
  end
end
