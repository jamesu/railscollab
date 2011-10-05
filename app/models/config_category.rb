#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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

class ConfigCategory < ActiveRecord::Base
  #has_many :config_options

  def display_name
    I18n.t "category_#{self.name}_name"
  end

  def display_description
    I18n.t "category_#{self.name}_description"
  end

  def options
    @config_options ||= ConfigOption.where(:category_name => self.name).order('config_options.option_order ASC')
  end
end
