class PasswordsController < ApplicationController
  layout 'dialog'
  before_action :find_user, only: [:edit, :update]
  before_action :validate_token, only: [:edit, :update]

  def new
  end

  def create
    @your_email = params[:your_email]

    unless @your_email =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
      error_status(false, :invalid_email)
      render action: 'new'
      return
    end

    user = User.where(email: @your_email).first
    if user.nil?
      error_status(false, :invalid_email_not_in_use)
      render action: 'new'
      return
    end

    # Send the reset!
    MailNotifier.password_reset(user).deliver_now
    error_status(false, :forgot_password_sent_email)
    redirect_to login_path
  end

  def edit
    @initial_signup = params.has_key? :initial
  end

  def update
    @initial_signup = params.has_key? :initial

    @password_data = params[:user]

    @user.password = @password_data[:password]
    if @user.save
      error_status(false, :password_changed)
      session['user_id'] = @user.id
      redirect_to root_path
    else
      render action: 'edit'
    end
  end

  protected

  def page_title
    case action_name
      when 'new', 'create' then I18n.t('forgot_password')
      when 'edit', 'update' then @initial_signup ? I18n.t('set_password') : I18n.t('reset_password')
    end
  end

  def find_user
    begin
      @user = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      error_status(false, :invalid_request)
      redirect_to login_path
    end
  end

  def validate_token
    unless @user.password_reset_key == params[:confirm]
      error_status(false, :invalid_request)
      redirect_to login_path
    end
  end

  def protect?(action)
    false
  end
end
