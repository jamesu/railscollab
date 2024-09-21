class Api::MessagesController < ApplicationController

  # GET /api/v1/projects/:project_id/messages
  def index
    render json: { messages: @messages }, status: :ok
  end

  # GET /api/v1/projects/:project_id/messages/:id
  def show
    authorize! :show, @message

    render json: { message: @message }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :create_message, @active_project

    @message = @active_project.messages.build(message_params)

    if @message.save
      render json: { message: @message }, status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/messages/:id
  # PATCH /api/v1/projects/:project_id/messages/:id
  def update
    authorize! :edit, @message

    @message.attributes = message_params
    @message.updated_by = @logged_user

    if @message.save
      render json: { message: @message }, status: :ok
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/messages/:id
  def destroy
    authorize! :delete, @message

    @message.updated_by = @logged_user
    @message.destroy

    render json: {}, status: :ok
  end

protected

  def message_params
    params.fetch(:message, {}).permit(:title, :text, :milestone_id, :category_id, :is_private, :is_important, :comments_enabled)
  end

  def load_message_category
    authorize! :show, @category

    begin
      @category = @active_project.categories.find(params[:category_id])
    rescue
      @category = nil
    end
  end

  def load_related_object
    load_message_category
    @message = @active_project.messages.find(params[:id])
  end

  def load_related_object_index
    load_message_category
    
    msg_conditions = {}
    msg_conditions["category_id"] = @category.id unless @category.nil?
    msg_conditions["is_private"] = false unless @logged_user.member_of_owner?
    @messages = @active_project.messages.where(msg_conditions).all
  end

end
