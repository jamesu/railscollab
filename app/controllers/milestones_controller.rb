#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
# Portions Copyright (C) René Scheibe
# Portions Copyright (C) Ariejan de Vroom
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

class MilestonesController < ApplicationController
  layout "project_website"

  after_action :user_track, :only => [:index, :show]

  def index
    @content_for_sidebar = "index_sidebar"

    respond_to do |format|
      format.html {
        index_lists(@logged_user.member_of_owner?, false)
      }
      format.json {
        @milestones = @logged_user.member_of_owner? ? @active_project.milestones : @active_project.milestones.is_public
        render json: @milestones.to_json
      }
    end
  end

  def show
    authorize! :show, @milestone
  end

  def new
    authorize! :create_milestone, @active_project
    @milestone = @active_project.milestones.build
  end

  def create
    authorize! :create_milestone, @active_project
    @milestone = @active_project.milestones.build

    milestone_attribs = milestone_params
    @milestone.attributes = milestone_attribs
    @milestone.created_by = @logged_user

    saved = @milestone.save
    if saved
      MailNotifier.milestone(@milestone.user, @milestone).deliver_now if params[:send_notification] and @milestone.user
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_milestone)
          redirect_back_or_default(@milestone.object_url)
        }
        format.json { render json: @milestone.to_json, status: :created, location: @milestone }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("milestone_form", partial: "milestones/milestone_form") }
        format.html { render action: "new" }
        format.json { render json: @milestone.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :edit, @milestone
  end

  def update
    authorize! :edit, @milestone

    milestone_attribs = milestone_params
    @milestone.attributes = milestone_attribs

    @milestone.updated_by = @logged_user

    saved = @milestone.save

    respond_to do |format|
      if saved
        MailNotifier.milestone(@milestone.user, @milestone).deliver_now if params[:send_notification] and @milestone.user
        format.html {
          error_status(false, :success_edited_milestone)
          redirect_back_or_default(@milestone.object_url)
        }
        format.json { head :ok }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("milestone_form", partial: "milestones/milestone_form") }
        format.html { render action: "edit" }
        format.json { render json: @milestone.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :delete, @milestone

    @on_page = (params[:on_page] || "").to_i == 1
    @removed_id = @milestone.id
    @milestone.updated_by = @logged_user
    @milestone.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_milestone)
        redirect_back_or_default(project_milestones_url(@active_project))
      }
      format.json { head :ok }
    end
  end

  def complete
    authorize! :change_status, @milestone
    return error_status(true, :milestone_already_completed) if (@milestone.is_completed?)

    @milestone.set_completed(true, @logged_user)

    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default project_milestone_path(@active_project, id: @milestone.id)
  end

  def open
    authorize! :change_status, @milestone
    return error_status(true, :milestone_already_open) unless (@milestone.is_completed?)

    @milestone.set_completed(false, @logged_user)

    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default project_milestone_path(@active_project, id: @milestone.id)
  end

  private

  def current_tab
    :milestones
  end

  def current_crumb
    case action_name
    when "index" then :milestones
    when "new", "create" then :add_milestone
    when "edit", "update" then :edit_milestone
    when "show" then @milestone.name
    else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << { title: :milestones, url: project_milestones_path(@active_project) } unless action_name == "index"
    crumbs
  end

  def page_actions
    @page_actions = []

    if action_name == "index"
      if can? :create_milestone, @active_project
        @page_actions << { title: :add_milestone, url: new_project_milestone_path(@active_project), ajax: true }
      end
    elsif action_name == "show"
      if not @milestone.is_completed?
        if can? :create_message, @active_project
          @page_actions << { title: :add_message, url: new_project_message_path(@active_project, milestone_id: @milestone.id) }
        end
        if can? :create_task_list, @active_project
          @page_actions << { title: :add_task_list, url: new_project_task_list_path(@active_project, milestone_id: @milestone.id) }
        end
      end
    end

    @page_actions
  end

  def milestone_params
    params.require(:milestone).permit(:name, :description, :due_date, :assigned_to_id, :is_private)
  end

  def load_related_object
    begin
      @milestone = @active_project.milestones.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_milestone, {}, false)
      redirect_back_or_default project_milestones_path(@active_project)
      return false
    end

    true
  end

  def index_lists(include_private, calendar_only)
    @time_now = Time.zone.now

    unless calendar_only
      @late_milestones = @active_project.milestones.late
      @late_milestones = @late_milestones.is_public unless include_private
    end
    @upcoming_milestones = Milestone.all_assigned_to(@logged_user, nil, @time_now.utc.to_date, nil, [@active_project])
    unless calendar_only
      @completed_milestones = @active_project.milestones.completed
      @completed_milestones = @completed_milestones.is_public unless include_private
    end

    end_date = (@time_now + 14.days).to_date
    @calendar_milestones = @upcoming_milestones.select { |m| m.due_date < end_date }.group_by do |obj|
      date = obj.due_date.to_date
      "#{date.month}-#{date.day}"
    end
  end
end
