class Api::CommentsController < ApplicationController

  # GET /api/v1/projects/:project_id/comments
  def index
    render json: { comments: @comments }, status: :ok
  end

  # GET /api/v1/projects/:project_id/comments/:id
  def show
    authorize! :show, @comment

    render json: { comment: @comment }, status: :ok
  end

  # POST /api/v1/projects
  def create
    authorize! :comment, @commented_object

    @comment = Comment.new()
    @comment.rel_object = @commented_object
    @comment.attributes = comment_params
    @comment.rel_object = @commented_object
    @comment.created_by = @logged_user
    @comment.author_homepage = request.remote_ip

    if @comment.save
      render json: { comment: @comment }, status: :created
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/projects/:project_id/comments/:id
  # PATCH /api/v1/projects/:project_id/comments/:id
  def update
    authorize! :edit, @comment

    @commented_object = @comment.rel_object
    @active_project = @commented_object.project

    @comment.attributes = comment_params
    @comment.updated_by = @logged_user

    if @comment.save
      render json: { comment: @comment }, status: :ok
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/comments/:id
  def destroy
    authorize! :delete, @comment

    @comment.updated_by = @logged_user
    @comment.destroy

    render json: {}, status: :ok
  end

protected

  def comment_params
    params.require(:comment).permit(:text, :is_private)
  end

  def comment_route_map
    [[:message_id, Message],
     [:milestone_id, Milestone],
     [:file_id, ProjectFile],
     [:task_id, Task],
     [:task_list_id, TaskList],
     [:project_id, Project]]
  end

  def find_comment_object
    comment_route_map.each do |map|
      if params.has_key?(map[0])
        return [map[1], params[map[0]]]
      end
    end

    return [nil, nil]
  end

  def load_assoc_object
    begin
      @object_class, rel_id = find_comment_object

      #puts "KLASS=#{@object_class.inspect} ident=#{rel_id} params=#{params}"

      if @object_class.nil?
        raise ActiveRecord::RecordNotFound
      end

      # Find object
      @commented_object = @object_class.find(rel_id)
      raise ActiveRecord::RecordNotFound if @commented_object.nil?

      authorize! :show, @commented_object
    end
  end

  def load_related_object
    load_assoc_object
    @comment = @commented_object.comments.find(params[:id])
  end

  def load_related_object_index
    load_assoc_object
    @comments = @logged_user.member_of_owner? ? @commented_object.comments : @commented_object.comments.is_public
  end
end
