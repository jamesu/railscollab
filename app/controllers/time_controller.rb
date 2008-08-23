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

class TimeController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => :delete,
  		 :add_flash => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'project' }

  before_filter :process_session
  before_filter :obtain_time, :except => [:index, :add, :by_task]
  before_filter :prepare_times, :only => [:index, :by_task, :export]
  after_filter  :user_track, :only => [:index, :view, :by_task] 
  
  def index
    if not @logged_user.has_permission(@active_project, :can_manage_time)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'project'
    end
    
    @project = @active_project
    
    @times = @project.project_times.find(:all, :conditions => @time_conditions, :page => {:size => AppConfig.times_per_page, :current => @current_page}, :order => "#{@sort_type} #{@sort_order}")
    @pagination = []
    @times.page_count.times {|page| @pagination << page+1}
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  def by_task
    if not @logged_user.has_permission(@active_project, :can_manage_time)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'project'
    end
    
    @project = @active_project
    
    @tasks = ProjectTime.find_by_task_list({:order => "#{@active_project.connection.quote_column_name 'order'} DESC"}, @time_conditions, "#{@sort_type} #{@sort_order}")
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  def view
    if not @time.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'time'
      return
    end
  end
  
  def add
    @time = ProjectTime.new
    
    if not ProjectTime.can_be_created_by(@logged_user, @active_project)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'time'
      return
    end
    
    @open_task_lists = @active_project.project_task_lists.open(@logged_user.member_of_owner?)
    
    case request.method
      when :post
        time_attribs = params[:time]
        
        @time.attributes = time_attribs
        
        @time.project = @active_project
        @time.created_by = @logged_user
        
        if @time.save
          error_status(false, :success_added_time)
          redirect_back_or_default :controller => 'time'
        end
    end
  end
  
  def edit
    if not @time.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'time'
      return
    end
    
    @open_task_lists = @active_project.project_task_lists.open(@logged_user.member_of_owner?)
    
    case request.method
      when :post
        time_attribs = params[:time]
        
        @time.attributes = time_attribs
        @time.updated_by = @logged_user
        
        if @time.save
          error_status(false, :success_edited_time)
          redirect_back_or_default :controller => 'time', :id => @time.id
        end
    end
  end
  
  def delete
    if not @time.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'time'
      return
    end
    
    @time.updated_by = @logged_user
    @time.destroy
    
    error_status(false, :success_deleted_time)
    redirect_back_or_default :controller => 'time'
  end

private

  def obtain_time
    begin
      @time = @active_project.project_times.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_time)
      redirect_back_or_default :controller => 'time'
      return false
    end
    
    return true
  end
  
  def prepare_times
    @current_page = params[:page].to_i
    @current_page = 0 unless @current_page > 0
    
    @time_conditions = @logged_user.member_of_owner? ? {} : {'is_private' => false}
    @sort_type = params[:orderBy]
    @sort_type = 'created_on' unless ['done_date', 'hours'].include?(params[:orderBy])
    @sort_order = 'DESC'
  end
  
end
