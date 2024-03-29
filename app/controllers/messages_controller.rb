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

class MessagesController < ApplicationController
  layout "project_website"

  after_action :user_track, only: [:index, :show]

  def index
    begin
      @category = @active_project.categories.find(params[:category_id])
    rescue
      @category = nil
    end

    unless @category.nil?
      authorize! :show, @category
    end

    # conditions
    msg_conditions = {}
    msg_conditions["category_id"] = @category.id unless @category.nil?
    msg_conditions["is_private"] = false unless @logged_user.member_of_owner?

    respond_to do |format|
      format.html {
        @content_for_sidebar = "index_sidebar"

        @page = params[:page].to_i
        @page = 1 unless @page > 0
        @messages = @active_project.messages.where(msg_conditions)
          .page(@page).per(Rails.configuration.railscollab.messages_per_page)

        @pagination = []
        @messages.total_pages.times { |page| @pagination << page + 1 }

        # Important messages (html only)
        important_conditions = { "is_important" => true }
        important_conditions["category_id"] = @category.id unless @category.nil?
        important_conditions["is_private"] = false unless @logged_user.member_of_owner?
        @important_messages = @active_project.messages.where(important_conditions)

        render template: "messages/index"
      }
      format.json {
        @messages = @active_project.messages.where(msg_conditions)
          .offset(params[:offset])
          .limit(params[:limit] || Rails.configuration.railscollab.messages_per_page)
        render json: @messages.to_json
      }
    end
  end

  def show
    authorize! :show, @message

    @private_object = @message.is_private

    @subscribers = @message.subscribers
    @content_for_sidebar = "view_sidebar"

    respond_to do |format|
      format.html { }
      format.json {
        render json: @message.to_json
      }
    end
  end

  def new
    authorize! :create_message, @active_project

    @message = @active_project.messages.build()

    # Set milestone
    @message.milestone_id = @milestone.id if @milestone

    # Grab default category
    begin
      @category = @active_project.categories.find(params[:category_id])
    rescue ActiveRecord::RecordNotFound
      @category = nil
    end

    if @category
      @message.category_id = @category.id
    else
      @category = @active_project.categories.where(["name = ?", Rails.configuration.railscollab.default_project_message_category]).first
    end

    @message.comments_enabled = true unless (message_params and message_params.has_key?(:comments_enabled))

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @message.to_json }
    end
  end

  def edit
    authorize! :edit, @message
  end

  def create
    authorize! :create_message, @active_project

    @message = @active_project.messages.build(message_params)

    message_attribs = message_params
    @message.attributes = message_attribs
    @message.created_by = @logged_user

    saved = @message.save
    estatus = :success_added_message

    if saved
      # Notify the subscribers
      unless params[:notify_user].nil?
        valid_users = params[:notify_user].collect do |user_id|
          real_id = user_id.to_i
          next if real_id == @logged_user.id # will be subscribed below

          number_of_users = Person.count(["user_id = ? AND project_id = ?", real_id, @active_project.id])
          next if number_of_users == 0

          real_id
        end.compact

        User.find(valid_users).each do |user|
          @message.ensure_subscribed(user)
          @message.send_notification(user)
        end
      end

      # Subscribe
      @message.ensure_subscribed(@logged_user) if @message.class == Message

      # Handle uploaded files
      if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private) != params[:uploaded_files].length)
        estatus = :success_added_message_failed_attachments
        error_status(false, :success_added_message_failed_attachments)
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, estatus)
          redirect_back_or_default(@message.object_url)
        }

        format.json { render json: @message.to_json, status: :created, location: @message }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/message_form") }
        format.html { render action: "new" }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :edit, @message

    message_attribs = message_params
    @message.attributes = message_attribs

    @message.updated_by = @logged_user

    saved = @message.save
    estatus = :success_edited_message

    # handle uploaded files
    if saved
      if (!params[:uploaded_files].nil? and ProjectFile.handle_files(params[:uploaded_files], @message, @logged_user, @message.is_private) != params[:uploaded_files].length)
        estatus = :success_edited_message_failed_attachments
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, estatus)
          redirect_back_or_default(@message.object_url)
        }

        format.json { head :ok }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/message_form") }
        format.html { render action: "edit" }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    authorize! :delete, @message

    @message.updated_by = @logged_user
    @message.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message)
        redirect_back_or_default(project_messages_url(@active_project, category_id: params[:category_id]))
      }

      format.json { head :ok }
    end
  end

  def subscribe
    authorize! :show, @message

    @message.ensure_subscribed(@logged_user) if @message.class == Message

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message)
        redirect_back_or_default(project_message_url(@message.project, @message))
      }

      format.json { head :ok }
    end
  end

  def unsubscribe
    authorize! :show, @message

    @message.subscribers.delete(@logged_user)

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_message)
        redirect_back_or_default(project_message_url(@message.project, @message))
      }

      format.json { head :ok }
    end
  end

  private

  def page_title
    case action_name
    when "category" then I18n.t("category_messages", category: @category.name)
    else super
    end
  end

  def current_tab
    :messages
  end

  def current_crumb
    case action_name
    when "index" then :messages
    when "new", "create" then :add_message
    when "edit", "update" then :edit_message
    when "show" then @message.title
    else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << { title: :messages, url: project_messages_path(@active_project) } unless action_name == "index"
    crumbs << { title: @message.category.name, url: posts_project_category_path(@active_project, id: @message.category_id) } if action_name == "show" && @message.category
    crumbs
  end

  def page_actions
    @page_actions = []
    update_display_mode

    if action_name == "index"
      if can? :create_message, @active_project
        @page_actions << { title: :add_message, url: (@category.nil? ?
          new_project_message_path(@active_project) : new_project_message_path(@active_project, category_id: @category.id)) }
      end

      if @display_list
        @page_actions << { title: :as_summary, url: url_for(display: "summary") }
      else
        @page_actions << { title: :as_list, url: url_for(display: "list") }
      end
    end

    @page_actions
  end

  def message_params
    params.fetch(:message, {}).permit(:title, :text, :milestone_id, :category_id, :is_private, :is_important, :comments_enabled)
  end

  def load_related_object
    begin
      @message = @active_project.messages.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_message, {}, false)
      redirect_back_or_default project_messages_path(@active_project)
      return false
    end

    return true
  end
end
