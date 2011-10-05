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
    @content_for_sidebar = 'index_sidebar'
    
    respond_to do |format|
      format.html {
        index_lists(@logged_user.member_of_owner?, false)
      }
      format.xml  {
        @milestones = @logged_user.member_of_owner? ? @active_project.milestones : @active_project.milestones.is_public
        render :xml => @milestones.to_xml(:root => 'milestones')
      }
    end
  end

  def show
    authorize! :show, @milestone
  end

  def new
    authorize! :create_milestone, @active_project
    @milestone = @active_project.milestones.build
  end
  
  def create
    authorize! :create_milestone, @active_project
    @milestone = @active_project.milestones.build
    
    milestone_attribs = params[:milestone]
    @milestone.attributes = milestone_attribs
    @milestone.created_by = @logged_user
    
    saved = @milestone.save
    if saved
      @milestone.tags = milestone_attribs[:tags]
      Notifier.deliver_milestone(@milestone.user, @milestone) if params[:send_notification] and @milestone.user
    end
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_milestone)
          redirect_back_or_default(@milestone)
        }
        format.xml  { render :xml => @milestone.to_xml(:root => 'milestone'), :status => :created, :location => @milestone }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @milestone.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :edit, @milestone
  end
  
  def update
    authorize! :edit, @milestone
 
    milestone_attribs = params[:milestone]
    @milestone.attributes = milestone_attribs
    
    @milestone.updated_by = @logged_user
    @milestone.tags = milestone_attribs[:tags]

    saved = @milestone.save
    
    respond_to do |format|
      if saved
        Notifier.deliver_milestone(@milestone.user, @milestone) if params[:send_notification] and @milestone.user
        format.html {
          error_status(false, :success_edited_milestone)
          redirect_back_or_default(@milestone)
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @milestone.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :delete, @milestone

    @on_page = (params[:on_page] || '').to_i == 1
    @removed_id = @milestone.id
    @milestone.updated_by = @logged_user
    @milestone.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_milestone)
        redirect_back_or_default(milestones_url)
      }
      format.xml  { head :ok }
    end
  end

  def complete
    authorize! :change_status, @milestone
    return error_status(true, :milestone_already_completed) if (@milestone.is_completed?)

    @milestone.set_completed(true, @logged_user)
    
    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default milestone_path(:id => @milestone.id)
  end

  def open
    authorize! :change_status, @milestone
    return error_status(true, :milestone_already_open) unless (@milestone.is_completed?)

    @milestone.set_completed(false, @logged_user)
    
    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default milestone_path(:id => @milestone.id)
  end

  private

  def obtain_milestone
    begin
      @milestone = @active_project.milestones.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_milestone)
      redirect_back_or_default milestones_path
      return false
    end

    true
  end

  def index_lists(include_private, calendar_only)
    @time_now = Time.zone.now

    unless calendar_only
      @late_milestones = @active_project.milestones.late
      @late_milestones = @late_milestones.is_public unless include_private
    end
    @upcoming_milestones = Milestone.all_assigned_to(@logged_user, nil, @time_now.utc.to_date, nil, [@active_project])
    unless calendar_only
      @completed_milestones = @active_project.milestones.completed
      @completed_milestones = @completed_milestones.is_public unless include_private
    end

    end_date = (@time_now + 14.days).to_date
    @calendar_milestones = @upcoming_milestones.select{|m| m.due_date < end_date}.group_by do |obj|
      date = obj.due_date.to_date
      "#{date.month}-#{date.day}"
    end
  end
end
