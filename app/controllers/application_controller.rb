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
  include SslRequirement
  include AuthenticatedSystem

  protect_from_forgery
  clear_helpers
  helper :navigation

  before_filter :reload_owner
  before_filter :login_required
  before_filter :logged_user_info
  before_filter :set_time_zone

protected

  rescue_from CanCan::AccessDenied do |exception|
    return error_status(true, :insufficient_permissions)
  end

  def ssl_required?
	Rails.configuration.using_ssl
  end

  def error_status(error, message, args={})
  	flash[:error] = error
  	flash[:message] = I18n.t(message, args)
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
