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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require_dependency "login_system"

class String
	def twist(twister)
	  return self if self.length != twister.length
	  
	  untwist_arr = self.split('')
	  twist_arr = twister.clone()
	  twister.length.times do |ti|
	  	twist_arr[twister[ti]] = untwist_arr[ti]
	  end
	  
      return twist_arr.join()
	end
	
	def untwist(twister)
	  return self if self.length != twister.length
      
      twist_arr = self.split('')
      untwist_arr = twister.clone()
      twister.length.times do |ti|
      	untwist_arr[ti] = twist_arr[twister[ti]]
      end
      
      return untwist_arr.join()
	end
	
	def valid_hash?
		(self =~ /^([a-f0-9]*)$/) != nil
	end
	
	def sanitize_filename
		fname = File.basename(self)
		fname.gsub(/[^\w\.\-]/,'_') 
	end
end

class ApplicationController < ActionController::Base
  include LoginSystem
  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_railscollab_session_id'
  
protected
  
  def process_session
    @active_project = nil
    
    # Set active project based on parameter or session
    
    if params[:active_project]
      begin
      @active_project = Project.find(params[:active_project])
      rescue ActiveRecord::RecordNotFound
        @active_project = nil
      end
    end
    
    @active_projects = @logged_user.active_projects
    
    return true
  end
  
  def verify_project
    if @active_project.nil?
      redirect_to :controller => 'dashboard'
      return false
    elsif not (@logged_user.is_admin || @logged_user.member_of(@active_project))
      redirect_to :controller => 'dashboard'
      return false
    end
    return true
  end
  
  def user_track
    if not @logged_user.nil?
      store_location
      @logged_user.last_visit = Time.now.utc
      @logged_user.save
    end
    true
  end
end
