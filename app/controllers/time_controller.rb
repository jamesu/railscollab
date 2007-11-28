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

class TimeController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => :delete,
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'project' }

  before_filter :login_required
  before_filter :process_session
  before_filter :obtain_time, :except => [:index, :add]
  after_filter  :user_track, :only => [:index, :view, :by_task] 
  
  def index
    @project = @active_project

    current_page = params[:page].to_i
    current_page = 0 unless current_page > 0
    
    time_conditions = @logged_user.member_of_owner? ? "project_id = ?" : "project_id = ? AND is_private = false"
    sort_type = params[:orderBy]
    sort_type = 'created_on' unless ['done_date', 'hours'].include?(params[:orderBy])
    sort_order = 'DESC'
    
    @times = ProjectTime.find(:all, :conditions => [time_conditions, @project.id], :page => {:size => AppConfig.times_per_page, :current => current_page}, :order => "#{sort_type} #{sort_order}")
    @pagination = []
    @times.page_count.times {|page| @pagination << page+1}
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  def by_task
  end
  
  def view
    begin
      @time = ProjectTime.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid time record"
      redirect_back_or_default :controller => 'time'
      return
    end
    
    if not @time.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'time'
      return
    end
  end
  
  def add
    @time = ProjectTime.new
    
    if not ProjectTime.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'time'
      return
    end
    
    @open_task_lists = @active_project.project_task_lists.open
    
    case request.method
      when :post
        time_attribs = params[:time]
        
        @time.attributes = time_attribs
        
        @time.project = @active_project
        @time.created_by = @logged_user
        
        if @time.save
          flash[:flash_success] = "Successfully added time record"
          redirect_back_or_default :controller => 'time'
        end
    end
  end
  
  def edit
    begin
      @time = ProjectTime.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid time record"
      redirect_back_or_default :controller => 'time'
      return
    end
    
    if not @time.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'time'
      return
    end
    
    @open_task_lists = @active_project.project_task_lists.open
    
    case request.method
      when :post
        time_attribs = params[:time]
        
        @time.attributes = time_attribs
        @time.updated_by = @logged_user
        
        if @time.save
          flash[:flash_success] = "Successfully edited time record"
          redirect_back_or_default :controller => 'time', :id => @time.id
        end
    end
  end
  
  def delete
    if not @time.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'time'
      return
    end
    
    @time.updated_by = @logged_user
    @time.destroy
    
    flash[:flash_success] = "Successfully deleted time record"
    redirect_back_or_default :controller => 'time'
  end

private

  def obtain_time
    begin
      @time = ProjectTime.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid time record"
      redirect_back_or_default :controller => 'time'
      return false
    end
    
    return true
  end
  
end
