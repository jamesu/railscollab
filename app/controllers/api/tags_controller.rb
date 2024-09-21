class Api::TagsController < ApplicationController
  before_action :get_related_object

  def index

  end

  def get_related_object
    if !params[:project_id].nil?
      Project.find(params[:project_id].to_i)
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
