=begin
RailsCollab
-----------

Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)

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

class UserController < ApplicationController

  layout 'dashboard'
  
  verify :method => :post,
  		 :only => [ :delete ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'project' }

  before_filter :login_required
  before_filter :process_session
  after_filter :user_track, :only => [:index, :card]
  
  def index
  	render :text => 'Hahaha!'
  end
  
  def add
    if not User.can_be_created_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    @user = User.new
    @company = @logged_user.company
    
    case request.method
      when :get
	    begin
	      if @logged_user.member_of_owner? and !params[:company_id].nil?
	      	@company = Company.find(params[:company_id])
	      end
	    rescue ActiveRecord::RecordNotFound
	      flash[:flash_error] = "Invalid company"
	      redirect_back_or_default :controller => 'dashboard'
	      return
	    end
	    
	    @user.company_id = @company.id
	    @user.timezone = @company.timezone

      when :post
        user_attribs = params[:user]
        
	    # Process credentials
        
        user_credentials = params[:credentials]
        if not user_credentials[:password]
          @user.errors.add(:password, "Required")
        else
	      if not user_credentials[:password] == user_credentials[:password_confirmation]
	        @user.errors.add(:password_confirmation, "Does not match")
	      end
        end
         
        if @user.errors.length > 0
        	return
        end
        
        # Process extra parameters
        
        @user.username = user_attribs[:username]
        @user.password = user_credentials[:password]
        if @logged_user.member_of_owner?
        	@user.company_id = user_attribs[:company_id]
        	@user.is_admin = user_attribs[:is_admin]
        	@user.auto_assign = user_attribs[:auto_assign]
        else
        	@user.company_id = @company.id
        end
        
        if user_attribs[:identity_url]
        	@user.identity_url = user_attribs[:identity_url]
        end
        
        # Process core parameters
        
        @user.attributes = user_attribs
        @user.created_by = @logged_user
        
        # Send it off
        
        if @user.save
          #ApplicationLog.new_log(@user, @logged_user, :add, true)
          flash[:flash_success] = "Successfully added user"
          redirect_back_or_default :controller => 'company', :action => 'view_client', :id => @company.id
        end
    end
  end
  
  def edit
     # Note: doesn't seem to have been implemented in ActiveCollab
    flash[:flash_success] = "Unimplemented"
    redirect_back_or_default :controller => 'dashboard'
  end
  
  def delete
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid user"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    if not @user.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    old_id = @user.id
    old_name = @user.display_name
    
    @user.destroy
    ApplicationLog::new_log(@milestone, @logged_user, :delete, true)
    
    flash[:flash_success] = "Deleted user #{old_name}"
    
    redirect_back_or_default :controller => 'company', :action => 'view', :id => old_id
  end
  
  def card
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid user"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
    
    if not @user.can_be_viewed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'dashboard'
      return
    end
  end
  
end
