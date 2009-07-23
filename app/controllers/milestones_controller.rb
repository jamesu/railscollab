#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
# Portions Copyright (C) René Scheibe
# Portions Copyright (C) Ariejan de Vroom
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

class MilestonesController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  before_filter :obtain_milestone, :except => [:index, :new, :create]
  after_filter  :user_track,       :only   => [:index, :show]

  def index
    include_private = @logged_user.member_of_owner?
    @content_for_sidebar = 'index_sidebar'
    
    respond_to do |format|
      format.html {  
        @time_now = Time.zone.now
  	
        @late_milestones = @active_project.project_milestones.late(include_private)
        @upcoming_milestones = ProjectMilestone.all_assigned_to(@logged_user, nil, @time_now.utc.to_date, (@time_now.utc + 14.days).to_date, [@active_project])
        @completed_milestones = @active_project.project_milestones.completed(include_private)

        end_date = (@time_now + 14.days).to_date
        @calendar_milestones = @upcoming_milestones.group_by do |obj| 
          date = obj.due_date.to_date
          "#{date.month}-#{date.day}"
        end
      }
      format.xml  {
        @milestones = include_private ? @active_project.project_milestones : @active_project.project_milestones.public
        render :xml => @milestones.to_xml(:root => 'milestones')
      }
    end
  end

  def show
    return error_status(true, :insufficient_permissions) unless @milestone.can_be_seen_by(@logged_user)
  end

  def new
    return error_status(true, :insufficient_permissions) unless (ProjectMilestone.can_be_created_by(@logged_user, @active_project))
    @milestone = @active_project.project_milestones.build
  end
  
  def create
    return error_status(true, :insufficient_permissions) unless (ProjectMilestone.can_be_created_by(@logged_user, @active_project))
    @milestone = @active_project.project_milestones.build
    
    milestone_attribs = params[:milestone]
    @milestone.attributes = milestone_attribs
    @milestone.created_by = @logged_user
    
    saved = @milestone.save
    if saved
      @milestone.tags = milestone_attribs[:tags]
    end
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_milestone)
          redirect_back_or_default(@milestone)
        }
        format.js {}
        format.xml  { render :xml => @milestone.to_xml(:root => 'milestone'), :status => :created, :location => @milestone }
      else
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @milestone.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    return error_status(true, :insufficient_permissions) unless @milestone.can_be_edited_by(@logged_user)
  end
  
  def update
    return error_status(true, :insufficient_permissions) unless @milestone.can_be_edited_by(@logged_user)
 
    milestone_attribs = params[:milestone]
    @milestone.attributes = milestone_attribs
    
    @milestone.updated_by = @logged_user
    @milestone.tags = milestone_attribs[:tags]

    saved = @milestone.save
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_edited_milestone)
          redirect_back_or_default(@milestone)
        }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @milestone.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    return error_status(true, :insufficient_permissions) unless (@milestone.can_be_deleted_by(@logged_user))

    @milestone.updated_by = @logged_user
    @milestone.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_milestone)
        redirect_back_or_default(milestones_url)
      }
      format.js {}
      format.xml  { head :ok }
    end
  end

  def complete
    return error_status(true, :insufficient_permissions) unless (@milestone.status_can_be_changed_by(@logged_user))
    return error_status(true, :milestone_already_completed) if (@milestone.is_completed?)

    @milestone.set_completed(true, @logged_user)
    
    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default milestone_path(:id => @milestone.id)
  end

  def open
    return error_status(true, :insufficient_permissions) unless (@milestone.status_can_be_changed_by(@logged_user))
    return error_status(true, :milestone_already_open) unless (@milestone.is_completed?)

    @milestone.set_completed(false)
    
    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default milestone_path(:id => @milestone.id)
  end

  private

  def obtain_milestone
    begin
      @milestone = @active_project.project_milestones.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_milestone)
      redirect_back_or_default milestones_path
      return false
    end

    true
  end
end
