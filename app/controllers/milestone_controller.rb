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

class MilestoneController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete, :complete, :open ],
  		 :add_flash => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'project' }

  before_filter :process_session
  before_filter :obtain_milestone, :except => [:index, :add]
  after_filter  :user_track, :only => [:index, :view]
  
  def index
  	include_private = @logged_user.member_of_owner?
  	
    @late_milestones = @active_project.project_milestones.late(include_private)
    @today_milestones = @active_project.project_milestones.todays(include_private)
    @upcoming_milestones = @active_project.project_milestones.upcoming(include_private)
    @completed_milestones = @active_project.project_milestones.completed(include_private)
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  def view
    if not @milestone.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end
  end
  
  def add
    @milestone = ProjectMilestone.new
    
    if not ProjectMilestone.can_be_created_by(@logged_user, @active_project)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end
        
    case request.method
      when :post
        milestone_attribs = params[:milestone]
        
        @milestone.attributes = milestone_attribs
        
        @milestone.created_by = @logged_user
        @milestone.project = @active_project
        
        if @milestone.save
          @milestone.tags = milestone_attribs[:tags]
          
          error_status(false, :success_added_milestone)
          redirect_back_or_default :controller => 'milestone'
        end
    end 
  end
  
  def edit
    if not @milestone.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    case request.method
      when :post
        milestone_attribs = params[:milestone]
        
        @milestone.attributes = milestone_attribs
        @milestone.updated_by = @logged_user
        @milestone.tags = milestone_attribs[:tags]
        
        if @milestone.save
          error_status(false, :success_edited_milestone)
          redirect_back_or_default :controller => 'milestone'
        end
    end     
  end
  
  def delete
    if not @milestone.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    @milestone.updated_by = @logged_user
    @milestone.destroy
    
    error_status(false, :success_deleted_milestone)
    redirect_back_or_default :controller => 'milestone'
  end
  
  def complete
    if not @milestone.status_can_be_changed_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end
   
    if @milestone.is_completed?
      error_status(true, :milestone_already_completed)
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
	@milestone.set_completed(true, @logged_user)
    
    if not @milestone.save
      error_status(true, :error_saving)
    end
    
    redirect_back_or_default :controller => 'milestone', :action => 'view', :id => @milestone.id
  end
  
  def open
    if not @milestone.status_can_be_changed_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    if !@milestone.is_completed?
      error_status(true, :milestone_already_open)
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
	@milestone.set_completed(false)
    
    if not @milestone.save
      error_status(true, :error_saving)
    end
    
    redirect_back_or_default :controller => 'milestone', :action => 'view', :id => @milestone.id
  end
  
private

  def obtain_milestone
    begin
      @milestone = @active_project.project_milestones.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_milestone)
      redirect_back_or_default :controller => 'milestone'
      return false
    end
    
    return true
  end
end
