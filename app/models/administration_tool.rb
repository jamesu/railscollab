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

class AdministrationTool < ActiveRecord::Base
  include ActionController::UrlWriter
  validates_uniqueness_of :name

  def self.admin_list
    AdministrationTool.all(:order => "#{self.connection.quote_column_name 'order'}")
  end

  def display_name
    "administration_tool_#{self.name}".to_sym.l
  end

  def display_description
    "administration_tool_#{self.name}_description".to_sym.l
  end

  def object_url
    url_for :only_path => true, :controller => self.controller, :action => self.action
  end
end
