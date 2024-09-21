class Api::SessionsController < ApiController
  def create
    logout_keeping_session!

    if !params[:token].nil?
      user = User.find_by_email(params[:token_email])
      user = nil if user.nil? or !user.twisted_token_valid?(params[:token])
    else
      user = User.authenticate(params[:login], params[:password])
    end

    if user
      self.current_user = user
      render json: {}
    else
      note_failed_signin
      render json: {}
    end
  end

  def destroy
    logout_killing_session!
    render json: {}, status: :ok
  end

  protected

  def note_failed_signin
    error_status(true, :login_failure, {}, false)
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def authorized?(action = action_name, resource = nil)
    true
  end
end
