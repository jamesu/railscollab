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

  protect_from_forgery
  clear_helpers
  helper :navigation

  before_action :reload_owner
  before_action :login_required
  before_action :logged_user_info
  before_action :set_time_zone

protected

  rescue_from Ability::AccessDenied do |exception|
    return error_status(true, :insufficient_permissions)
  end
  
  def error_status(error, message, args={}, continue_ok=true)
    if request.format == :html
      flash[:error] = error
      flash[:message] = t(message, *args)
    else
      @flash_error = error
      @flash_message = t(message, *args)
    end
    
    return unless (error and continue_ok)
    
    # Construct a reply with a relevant error
    respond_to do |format|
        format.html { redirect_back_or_default('/') }
        format.js { render(:update) do |page| 
                      page.replace_html('statusBar', h(flash[:message]))
                      page.show 'statusBar'
                    end }
        format.xml  { head(error ? :unprocessable_entity : :ok) }
    end
  end

  def set_time_zone
    Time.zone = @logged_user.time_zone if @logged_user
  end
  
  def reload_owner
    Company.owner(true)
  end

  def process_session
    # Set active project based on parameter or session
    @active_project = nil
    if params[:active_project]
      @active_project = Project.find(params[:active_project]) rescue ActiveRecord::RecordNotFound
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
    if @active_project.nil? or not (can?(:show, @active_project))
      error_status(false, :insufficient_permissions)
      redirect_to :controller => 'dashboard'
      return false
    end

    true
  end

  def user_track
    unless @logged_user.nil?
      store_location if request.method_symbol == :get and request.format == :html
      @logged_user.update_attribute('last_visit', Time.now.utc)
    end

    true
  end
end
