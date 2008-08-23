=begin
RailsCollab
-----------

Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class AccessController < ApplicationController

  layout 'dialog'
  
  filter_parameter_logging :password
  
  def index
    if @logged_user.nil?
      redirect_to :action => 'login'
    else
      redirect_to :controller => 'dashboard'
    end
  end
  
  def login
    case request.method
      when :post
        login_params = params[:login]
        remember = login_params[:remember]

        # Normal boring username + password
        @logged_user = User.authenticate(login_params['user'], login_params['password']) 

        if @logged_user.nil?
          error_status(true, :login_failure)
        else
          error_status(false, :login_success)
          redirect_back_or_default :controller => 'dashboard'

          session['user_id'] = @logged_user.id
        end
    end
  end
  
  def openid_login
    unless AppConfig.allow_openid
      error_status(true, :invalid_request)
      redirect_to :action => 'login'
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
        
        redirect_to :action => 'login'
      
      elsif result.unsuccessful?
        if result == :canceled
          error_status(true, :verification_cancelled)
        elsif !identity_url.nil?
          error_status(true, :failed_verification_openid_url, {:openid_url => identity_url})
        else
          error_status(true, :verification_failed)
        end
        
        redirect_to :action => 'login'
        
      else
        error_status(true, :unknown_response_status, {:status => result.message})
        redirect_to :action => 'login'
      end
    end
  end
    
  def logout
    session['user_id'] = nil
    redirect_to :controller => 'access', :action => 'login'
  end
  
  def forgot_password
    case request.method
      when :post
        @your_email = params[:your_email]
        
        if not @your_email =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
          error_status(false, :invalid_email)
          return
        end
        
        user = User.find(:first, :conditions => ['email = ?', @your_email])
        if user.nil?
          error_status(false, :invalid_email_not_in_use)
          return
        end
        
        # Send the reset!
        user.send_password_reset()
        error_status(false, :forgot_password_sent_email)
        redirect_to :action => 'login'
    end
  end
  
  def reset_password
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(false, :invalid_request)
      redirect_to :action => 'login'
      return
    end
    
    unless @user.password_reset_key == params[:confirm]
      error_status(false, :invalid_request)
      redirect_to :action => 'login'
    end
    
    @initial_signup = params.has_key? :initial
    
    case request.method
      when :post
        
        @password_data = params[:user]
            
        unless @password_data[:password]
          @user.errors.add(:password, :new_password_required.l)
          return
        end
          
        unless @password_data[:password] == @password_data[:password_confirmation]
          @user.errors.add(:password_confirmation, :does_not_match.l)
          return
        end
    
        @user.password = @password_data[:password]
        @user.save
        
        error_status(false, :password_changed)
        redirect_to :action => 'login'
        return
    end
  end

protected

  def protect?(action)
    false
  end  
end
