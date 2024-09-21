class Api::CompaniesController < ApplicationController

  # GET /api/v1/companies
  def index
    render json: { companies: @companies }, status: :ok
  end

  # GET /api/v1/companies/:id
  def show
    authorize! :show, @company
    
    render json: { company: @company }, status: :ok
  end

  # POST /api/v1/companies
  def create
    authorize! :create_company, current_user

    @company = Company.new
    @company.attributes = company_params
    @company.client_of = @owner
    @company.created_by = @logged_user

    if @company.save
      render json: { company: @company }, status: :created
    else
      render json: { errors: @company.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/companies/:id
  # PATCH /api/v1/companies/:id
  def update
    authorize! :edit, @company

    @company.attributes = company_params
    @company.updated_by = @logged_user

    if @company.save
      render json: { company: @company }, status: :ok
    else
      render json: { errors: @company.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/companies/:id
  def destroy
    authorize! :delete, @company
    
    @company.updated_by = @logged_user
    @company.destroy

    render json: { }, status: :ok
  end

protected

  def company_params
    params.require(:company).permit(:logo, :name, :time_zone, :email, :homepage, :phone_number, :fax_number, :address, :address2, :city, :state, :zipcode, :country, company_ids: [], perms: [], project_ids: [])
  end

  def load_related_object
    @company = Company.find(params[:id])
    @active_company = @company
  end

  def load_related_object_index
    @companies = [@owner] + @owner.clients
  end

end
