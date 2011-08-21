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

  def new
    redirect_to :controller => 'dashboard' unless @logged_user.nil?
  end

  def create
    username_login
    remember(@logged_user) if params['remember']
  end

  def destroy
    forget(@logged_user)
    redirect_to login_path
  end

  protected

  def username_login
    # Normal boring username + password
    debugger
    @logged_user = User.authenticate(params['login']['user'], params['login']['password'])

    if @logged_user.nil?
      error_status(true, :login_failure)
      render :action => 'new'
    else
      error_status(false, :login_success)
      redirect_back_or_default :controller => 'dashboard'

      session['user_id'] = @logged_user.id
    end
  end

  def protect?(action)
    false
  end
end
