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

class AdministrationController < ApplicationController

  before_filter :process_session
  
  def index
  end
  
  def company
  	@company = Company.owner(true)
  	render :template => 'company/view_client'
  end
  
  def members
  	@company = Company.owner(true)
  	@users = @company.users
  end
  
  def projects
  	@projects = @logged_user.projects
  end
  
  def clients
  	@clients = Company.owner.clients(true)
  end
  
  def configuration
      sys_conds = (params[:system].to_i == 1) ? [] : ['is_system = ?', false]
      @categories = ConfigCategory.find(:all, :conditions => sys_conds, :order => 'category_order DESC')
  end
  
  def tools
      @tools = AdministrationTool.admin_list
  end
  
  def upgrade
  	@versions = []
  end
  
  def authorize?(user)
  	return user.is_admin
  end
end
