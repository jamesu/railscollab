class Api::UsersController < ApplicationController

  # GET /api/v1/users
  def index
    render json: { users: @users }, status: :ok
  end

  # GET /api/v1/users/:id
  def show
    authorize! :show, @user

    render json: { user: @user }, status: :ok
  end

  # POST /api/v1/users
  def create
    authorize! :create_user, current_user

    @user = User.new

    @user.attributes = user_params
    @user.created_by = @logged_user
    @user.companies << @owner

    @auto_assign_users = @owner.auto_assign_users

    if @user.save
      render json: { user: @user }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/users/:id
  # PATCH /api/v1/users/:id
  def update
    authorize! :edit, @user

    @user.attributes = user_params
    @user.updated_by = @logged_user

    if @user.save
      render json: { user: @user }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/:id
  def destroy
    authorize! :delete, @user

    @user.updated_by = @logged_user
    @user.destroy
    render json: { }, status: :ok
  end

protected

  def user_permit_list
    return [:generate_password, :password, :password_confirmation, :display_name, :email, :time_zone, :title, :office_number, :office_number_ext, :fax_number, :mobile_number, :home_number, :new_account_notification]
  end

  def admin_user_params
    nl = user_permit_list
    nl << :username
    nl << :company_id
    nl << :is_admin
    nl << :auto_assign
    nl << :user_project
    nl << :project_permission
    params[:user].nil? ? {} : params[:user].permit(*nl, perms: [])
  end

  def user_params
    params.require(:user).permit(*user_permit_list)
  end

  def load_company
    if @logged_user.member_of_owner? and !params[:company_id].nil?
      @company = Company.find(params[:company_id])
    end
  end

  def load_related_object
    @user = User.find(params[:id])
    @active_user = @user
  end

end
