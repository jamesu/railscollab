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

class SessionsController < ApplicationController

  layout 'dialog'
  before_filter :use_openid, :only => [:new, :create]
  filter_parameter_logging :password

  def new
    redirect_to :controller => 'dashboard' unless @logged_user.nil?
  end

  def create
    remember = params['remember']
    if params[:openid_url]
      openid_login
    else
      username_login
    end
  end

  def destroy
    session['user_id'] = nil
    redirect_to login_path
  end

  protected

  def username_login
    # Normal boring username + password
    @logged_user = User.authenticate(params['user'], params['password'])

    if @logged_user.nil?
      error_status(true, :login_failure)
      render :action => 'new'
    else
      error_status(false, :login_success)
      redirect_back_or_default :controller => 'dashboard'

      session['user_id'] = @logged_user.id
    end
  end

  def openid_login
    unless AppConfig.allow_openid
      error_status(true, :invalid_request)
      redirect_to :action => 'new'
      return
    end

    authenticate_with_open_id(params[:openid_url]) do |result, identity_url, registration|
      if result.successful?
        log_user = User.openid_login(identity_url)

        if log_user.nil?
          error_status(true, :failed_login_openid_url, {:openid_url => identity_url})
        else
          error_status(false, :success_login_openid_url, {:openid_url => identity_url})
          redirect_back_or_default :controller => 'dashboard'
          session['user_id'] = log_user.id
          return
        end
      elsif result.unsuccessful?
        if result == :canceled
          error_status(true, :verification_cancelled)
        elsif !identity_url.nil?
          error_status(true, :failed_verification_openid_url, {:openid_url => identity_url})
        else
          error_status(true, :verification_failed)
        end
      else
        error_status(true, :unknown_response_status, {:status => result.message})
      end
      redirect_to :action => 'new'
    end
  end

  def use_openid
    @use_openid = (AppConfig.allow_openid and params['use_openid'].to_i == 1)
  end

  def protect?(action)
    false
  end
end
