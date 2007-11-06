=begin
RailsCollab
-----------
Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class AccessController < ApplicationController

  layout 'dialog'
  
  if AppConfig.allow_openid
  	open_id_consumer
  end
  
  def login
    case @request.method
      when :post
        login_params = params[:login]
        remember = login_params[:remember]
              
        # Normal boring username + password
        @logged_user = User.authenticate(login_params['user'], login_params['password']) 
        
        if !@logged_user.nil?
          flash[:flash_success]  = "Login successful"
          redirect_back_or_default :controller => "dashboard"
          
          session['user_id'] = @logged_user.id
        else
          flash[:flash_error]  = "Login unsuccessful"
        end
    end
  end
  
  def begin
    # If the URL was unusable (either because of network conditions,
    # a server error, or that the response returned was not an OpenID
    # identity page), the library will return HTTP_FAILURE or PARSE_ERROR.
    # Let the user know that the URL is unusable.
    case open_id_response.status
      when OpenID::SUCCESS
        # The URL was a valid identity URL. Now we just need to send a redirect
        # to the server using the redirect_url the library created for us.
    
        # redirect to the server
        redirect_to open_id_response.redirect_url((request.protocol + request.host_with_port + '/'), url_for(:action => 'complete'))
      else
        flash[:flash_error] = "Unable to find openid server for <q>#{params[:openid_url]}</q>"
        redirect_to :action => 'login'
    end
  end

  def complete
    case open_id_response.status
      when OpenID::FAILURE
        # In the case of failure, if info is non-nil, it is the
        # URL that we were verifying. We include it in the error
        # message to help the user figure out what happened.
        if open_id_response.identity_url
          flash[:flash_error] = "Verification of #{open_id_response.identity_url} failed. "
        else
          flash[:flash_error] = "Verification failed. "
        end
        flash[:message] += open_id_response.msg.to_s
    
      when OpenID::SUCCESS
        # Success means that the transaction completed without
        # error. If info is nil, it means that the user cancelled
        # the verification.
          
        log_user = User.openid_login(open_id_response.identity_url)
        if log_user.nil?
          flash[:flash_error] = "Failed login with identity #{open_id_response.identity_url}."
        else
          flash[:flash_success] = "You have successfully logged in with #{open_id_response.identity_url} as your identity."
          redirect_back_or_default :controller => "dashboard"
          session['user_id'] = log_user.id
          return
        end
    
      when OpenID::CANCEL
        flash[:flash_error] = "Verification cancelled."
    
      else
        flash[:flash_error] = "Unknown response status: #{open_id_response.status}"
    end
    redirect_to :action => 'login'
  end
  
  def logout
    session['user_id'] = nil
    redirect_to :controller => 'access', :action => 'login'
  end
  
  def forgot_password
    case @request.method
      when :post
        @your_email = params[:your_email]
        
        if not @your_email =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
          flash[:flash_error] = "Invalid email address"
          return
        end
        
        user = User.by_email(@your_email)
        if user.nil?
          flash[:flash_error] = "Email address not in use"
          return
        end
        
        # TODO
    end
  end
  
end
