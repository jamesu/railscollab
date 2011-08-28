#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

module ConfigurationsHelper
  def current_tab
    :configuration
  end

  def current_crumb
    case action_name
      when 'index' then I18n.t('configuration')
      else @category.display_name
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :configuration, :url => configurations_path} unless action_name == 'index'
    crumbs
  end

  def additional_stylesheets
    ['admin/config']
  end
end
