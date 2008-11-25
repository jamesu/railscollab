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

class AdministrationController < ApplicationController

  before_filter :process_session
  before_filter :user_track

  def index
  end
  
  def projects
  	@projects = @logged_user.projects
  end

  def people
    @company = Company.owner
  	@clients = Company.owner.clients(true)
  	
  	@companies = [@company] + @clients
  end

  def configuration
    sys_conds = (params[:system].to_i == 1) ? [] : ['is_system = ?', false]
    @categories = ConfigCategory.all(:conditions => sys_conds, :order => 'category_order DESC')
  end

  def tools
    @tools = AdministrationTool.admin_list
  end

  def upgrade
  	@versions = []
  end

  def authorize?(user)
  	user.is_admin
  end
end
