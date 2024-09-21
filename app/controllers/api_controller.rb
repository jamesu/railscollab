class ApiController < ActionController::Base
  include AuthenticatedSystem
  include ActiveStorage::SetCurrent

  before_action :set_default_format
  before_action :reload_owner
  before_action :login_required
  before_action :set_time_zone
  before_action :process_session

  before_action :load_related_object_index, only: [:index, :create]
  before_action :load_related_object, except: [:index, :create, :list]

  def can?(ability, instance)
    return false if @logged_user.nil?
    if @logged_user_can.nil?
      @logged_user_can = Ability.new.init(@logged_user)
    end
    return @logged_user_can.can?(ability, instance)
  end

  def verify_project
    if @active_project.nil? or not(can?(:show, @active_project))
      raise ActiveRecord::RecordInvalid
    end
  end

  def authorize!(action, instance)
    if !can?(action, instance)
      raise ActiveRecord::RecordInvalid
    end
  end

  def company_list
    list = [@owner] + @owner.clients
  end

  def reload_owner
    @owner = Company.instance_owner
  end

  def process_session
    @active_project = nil
    if params[:project_id]
      @active_project = Project.find(params[:project_id])
      authorize! :show, @active_project
    end
  end

  private

  def set_default_format
    request.format = :json
  end

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response

  def set_time_zone
    Time.zone = @logged_user.time_zone if @logged_user
  end

  def render_not_found_response
    render json: { error: 'Resource not found' }, status: :not_found
  end

  def render_unprocessable_entity_response(exception)
    render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def load_related_object
  end
  
  def load_related_object_index
  end

end
