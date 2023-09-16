#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class CategoriesController < ApplicationController
  layout "project_website"

  after_action :user_track, only: [:index, :show]

  def index
    @categories = @active_project.categories

    respond_to do |format|
      format.html { }
      format.json {
        render json: @categories.to_json
      }
    end
  end

  def show
    begin
      @category = @active_project.categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end

    authorize! :show, @category

    respond_to do |format|
      format.html {
        @content_for_sidebar = "messages/index_sidebar"
      }
      format.json {
        render json: @category.to_json
      }
    end
  end

  def new
    authorize! :create_message_category, @active_project

    @category = @active_project.categories.build()

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @category.to_json }
    end
  end

  def edit
    begin
      @category = @active_project.categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return error_status(true, :invalid_message_category)
    end

    authorize! :edit, @category
  end

  def create
    authorize! :create_message_category, @active_project

    @category = @active_project.categories.build(category_params)
    @category.created_by = @logged_user

    respond_to do |format|
      if @category.save
        format.html {
          error_status(false, :success_added_message_category)
          redirect_back_or_default(@category.object_url)
        }
        format.json { render json: @category.to_json, status: :created, location: @category }
      else
        format.html { render action: "new" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    begin
      @category = @active_project.categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end

    authorize! :edit, @category

    @category.updated_by = @logged_user

    respond_to do |format|
      if @category.update(category_params)
        format.html {
          error_status(false, :success_edited_message_category)
          redirect_back_or_default(@category.object_url)
        }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.xml
  def destroy
    begin
      @category = @active_project.categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end

    authorize! :delete, @category

    @category.updated_by = @logged_user
    @category.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message_category)
        redirect_back_or_default(categories_url)
      }
      format.json { head :ok }
    end
  end

  # /categories/1/posts
  # /categories/1/posts.xml
  def posts
    begin
      @category = @active_project.categories.find(params[:id])
    rescue
      return error_status(true, :invalid_message_category)
    end

    authorize! :show, @category

    # conditions
    msg_conditions = {}
    msg_conditions["is_private"] = false unless @logged_user.member_of_owner?

    # probably should make this more generic...
    if params[:display] == "list"
      session[:msglist] = true
    elsif params[:display] == "summary"
      session[:msglist] = false
    end
    @display_list = session[:msglist] || false

    respond_to do |format|
      format.html {
        @content_for_sidebar = "messages/index_sidebar"

        @page = params[:page].to_i
        @page = 1 unless @page > 0

        @messages = @category.messages.where(msg_conditions)
          .page(@page).per(Rails.configuration.railscollab.messages_per_page)

        @pagination = []
        @messages.total_pages.times { |page| @pagination << page + 1 }

        # Important messages (html only)
        important_conditions = { "is_important" => true }
        important_conditions["is_private"] = false unless @logged_user.member_of_owner?
        @important_messages = @active_project.messages.where(important_conditions)

        render template: "messages/index"
      }
      format.json {
        @messages = @category.messages.where(msg_conditions)
          .offset(params[:offset])
          .limit(params[:limit] || Rails.configuration.railscollab.messages_per_page)

        render json: @messages.to_json(only: [:id,
                                              :title,
                                              :created_by_id,
                                              :created_on,
                                              :updated_on,
                                              :is_private,
                                              :is_important,
                                              :milestone_id,
                                              :attached_files_count,
                                              :comments_enabled])
      }
    end
  end

  protected

  def page_title
    case action_name
    when "posts" then @category.name
    else super
    end
  end

  def current_tab
    :messages
  end

  def current_crumb
    case action_name
    when "new", "create" then :add_message_category
    when "edit", "update" then :edit_message_category
    when "index" then :messages
    when "posts" then @category.name
    else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << { title: :messages, url: project_messages_path(@active_project) }
    crumbs
  end

  def page_actions
    @page_actions = []

    if can? :create_message_category, @active_project
      @page_actions << { title: :add_category, url: new_project_category_path(@active_project) } if action_name == "index"
    end

    if can? :create_message, @active_project
      @page_actions << { title: :add_message, url: new_project_message_path(project_id: @active_project.id, category_id: @category.id) } if action_name == "posts"
    end

    if @display_list
      @page_actions << { title: :as_summary, url: url_for(display: "summary") }
    else
      @page_actions << { title: :as_list, url: url_for(display: "list") }
    end

    @page_actions
  end

  def category_params
    params.require(:category].permit(:name)
  end
end
