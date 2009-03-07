#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

require_dependency 'login_system'

class ApplicationController < ActionController::Base
  include LoginSystem

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_railscollab_session_id'

  protect_from_forgery

  before_filter :reload_owner
  before_filter :login_required
  before_filter :set_time_zone

protected

  def error_status(error, message, args={})
  	flash[:error] = error
  	flash[:message] = message.l_with_args(args)
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

    @active_projects = @logged_user.active_projects
    true
  end

  def verify_project
    if @active_project.nil? or not (@active_project.can_be_seen_by(@logged_user))
      error_status(false, :insufficient_permissions)
      redirect_to :controller => 'dashboard'
      return false
    end

    true
  end

  def user_track
    unless @logged_user.nil?
      store_location if request.method == :get and request.format == :html
      @logged_user.update_attribute('last_visit', Time.now.utc)
    end

    true
  end
end
