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

require_dependency 'user'

module LoginSystem

  protected

  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(user)
  #    user.login != "bob"
  #  end
  def authorize?(user)
    true
  end

  # overwrite this method if you only want to protect certain actions of the controller
  # example:
  #
  #  # don't protect the login and the about method
  #  def protect?(action)
  #    if ['action', 'about'].include?(action)
  #       return false
  #    else
  #       return true
  #    end
  #  end
  def protect?(action)
    true
  end

  # overwrite this method if you want to allow people to login via authentication tokens
  # example:
  #
  #  # don't protect the login and the about method
  #  def protect_token?(action)
  #    if ['feed', 'other_feed'].include?(action)
  #       return true
  #    else
  #       return false
  #    end
  #  end
  def protect_token?(action)
    false
  end

  def logged_user
    @logged_user ||= user_from_session || user_from_cookie
  end

  # login_required filter. add
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management.
  # for finer access control you can overwrite
  #
  #   def authorize?(user)
  #
  def login_required
    return true unless protect?(action_name)

    if protect_token?(action_name)
      return true if token_login_accepted
    end

    do_action = false

    if request.accepts.first == Mime::XML
      # HTTP basic authentication for XML / YAML requests
      @logged_user = nil

      authenticate_or_request_with_http_basic do |user_name, password|
        @logged_user = User.authenticate(user_name, password)
      end
    else
      # Session or cookie authentication
      session['user_id'] = logged_user.id unless logged_user.nil?

      do_action = true
    end

    # Don't exist? what a pity!
    if @logged_user.nil?
      # Check to see if we accept anonymous logins...
      if AppConfig.allow_anonymous
        @logged_user = User.first(:conditions => ['username = ?', 'Anonymous'])
        if @logged_user.nil?
          session['user_id'] = nil
          access_denied if do_action
          return false
        end
      else
        session['user_id'] = nil
        access_denied if do_action
        return false
      end
    end

    return true if authorize?(@logged_user)

    # store current location so that we can come back after the user logged in
    store_location

    # call overwriteable reaction to unauthorized access
    access_denied if do_action

    false
  end

  def token_login_accepted
    if params[:user].nil?
      @logged_user = nil
    else
      @logged_user = User.first(:conditions => ['id = ?', params[:user]])
    end

    # Don't exist? Not valid? what a pity!
    if @logged_user.nil? or !@logged_user.twisted_token_valid?(params[:token])
      return false
    end

    true
  end

  def user_from_cookie
    if token = cookies[:remember_token]
      return nil unless user = User.find_by_remember(token)
      return user if user.remember?
    end
  end

  def user_from_session
    User.first(:conditions => ['id = ?', session['user_id']]) if session['user_id']
  end

  def remember(user)
    user.remember_me!
    cookies[:remember_token] = { :value => user.remember, :expires => user.remember_expires_at }
  end

  def forget(user)
    user.forget_me! if user
    cookies.delete(:remember_token)
    session['user_id'] = nil
  end

  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation.
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
    redirect_to login_path
  end

  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session['return-to'] = request.request_uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session['return-to'].nil?
      redirect_to default
    else
      redirect_to session['return-to']
      session['return-to'] = nil
    end
  end
end
