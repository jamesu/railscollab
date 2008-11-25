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

class AccountController < ApplicationController
  layout 'administration'

  verify :method      => :post,
         :only        => [ :delete_avatar ],
         :add_flash   => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'account' }

  filter_parameter_logging :password

  before_filter :process_session
  before_filter :obtain_user, :except => [:index, :avatar]
  after_filter :user_track,   :only   => [:index]

  def index
  	@user = @logged_user
  end

  def update_permissions
  	unless @user.profile_can_be_updated_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'dashboard'
      return
  	end

    @projects = @user.company.projects
    @permissions = ProjectUser.permission_names()

    case request.method
    when :post
      user_project = params[:user_project]
      user_project ||= []

      # Grab the list of project id's specified
      project_list = user_project.select do |project_id|
        begin
          project = Project.find(project_id)
          project.can_be_managed_by(@logged_user)
        rescue ActiveRecord::RecordNotFound
          false
        end
      end

      # Associate project permissions with user
      project_permission = params[:project_permission]
      project_list.each do |project_id|
        permission_list = project_permission.nil? ? nil : project_permission[project_id]

        # Find permission list
        project_user = ProjectUser.first(:conditions => ['user_id = ? AND project_id = ?', @user.id, project_id])
        if project_user.nil?
          Project.find(project_id).users << @user
        end

        # Reset and update permissions
        if permission_list.nil?
          ProjectUser.update_all(ProjectUser.update_str({}, @user), ['user_id = ? AND project_id = ?', @user.id, project_id])
        else
          ProjectUser.update_all(ProjectUser.update_str(permission_list, @user), ['user_id = ? AND project_id = ?', @user.id, project_id])
        end
      end

      # Delete all permissions that aren't in the project list
      delete_list = @projects.collect do |project|
        unless project_list.include?(project.id.to_s)
          project.id
        else
          nil
        end
      end.compact

      unless delete_list.empty?
        ProjectUser.delete_all({ :user_id => @user.id, :project_id => delete_list })
      end

      #ApplicationLog.new_log(@project, @logged_user, :edit, true)

      error_status(false, :success_updated_permissions)
      redirect_to :controller => 'account', :action => 'update_permissions', :id => @user.id
    end
  end

  private

  def obtain_user
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_user)
      redirect_back_or_default :controller => 'dashboard'
      return false
    end

    true
  end
end
