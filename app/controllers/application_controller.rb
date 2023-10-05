#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
# Portions Copyright (C) René Scheibe
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include ActiveStorage::SetCurrent

  protect_from_forgery

  before_action :reload_owner
  before_action :login_required
  before_action :logged_user_info
  before_action :set_time_zone
  before_action :process_session
  before_action :load_related_object_index, only: [:index, :create, :new]
  before_action :load_related_object, except: [:index, :create, :new, :by_task, :list]
  before_action :config_page

  protected

  def error_status(error, message, args = {}, continue_ok = true)
    @flash_error = error
    @flash_message = t(message, *args)

    if request.format == :html
      flash[:error] = @flash_error
      flash[:message] = @flash_message
    end

    return if !error
    return if !continue_ok

    # Construct a reply with a relevant error
    respond_to do |format|
      format.html { redirect_back_or_default("/") }
      format.js {
        render(:update) do |page|
          page.replace_html("statusBar", h(flash[:message]))
          page.show "statusBar"
        end
      }
      format.json { head(error ? :unprocessable_entity : :ok) }
    end
  end

  def set_time_zone
    Time.zone = @logged_user.time_zone if @logged_user
  end

  def reload_owner
    Company.owner.reload
  end

  def process_session
    # Set active project based on parameter or session
    @active_project = nil
    if params[:project_id]
      @active_project = Project.find(params[:project_id]) rescue ActiveRecord::RecordNotFound
      return false unless verify_project
    end
  end

  def logged_user_info
    unless @logged_user.nil?
      @active_projects = @logged_user.active_projects.all
      @running_times = @logged_user.assigned_times.running.all
    end
  end

  def verify_project
    if @active_project.nil? or not(can?(:show, @active_project))
      error_status(false, :insufficient_permissions)
      redirect_to controller: "dashboard"
      return false
    end

    true
  end

  def user_track
    unless @logged_user.nil?
      store_location if request.method_symbol == :get and request.format == :html
      @logged_user.update_attribute("last_visit", Time.now.utc)
    end

    true
  end

  def can?(ability, instance)
    return false if @logged_user.nil?
    if @logged_user_can.nil?
      @logged_user_can = Ability.new.init(@logged_user)
    end
    return @logged_user_can.can?(ability, instance)
  end

  def authorize!(action, instance)
    if !can?(action, instance)
      error_status(false, :insufficient_permissions)
      false
    else
      true
    end
  end

  # navigation

  def page_title
    title = current_crumb
    title = I18n.t(title) if title.is_a? Symbol
    title
  end

  def current_crumb
    action_name.to_sym
  end

  def crumbs
    []
  end

  def extra_crumbs
    []
  end

  def page_actions
    @page_actions || []
  end

  def current_tab
    nil
  end

  def load_related_object_index
  end

  def load_related_object
  end

  def config_page
    @page_title = page_title
    @crumbs = crumbs
    @current_tab = current_tab
    @current_crumb = current_crumb
    @extra_crumbs = extra_crumbs
    @page_actions = page_actions
  end

end
