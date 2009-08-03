#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

module TimesHelper
  def current_tab
    :ptime
  end

  def current_crumb
    case action_name
      when 'index', 'by_task' then :ptime
      when 'new', 'create' then :add_time
      when 'edit', 'update' then :edit_time
      when 'show' then @time.name
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :ptime, :url => times_url} unless ['index', 'by_task'].include? action_name
    crumbs
  end

  def additional_stylesheets
    ['project/time']
  end

  def seconds_to_time(seconds)
    Time.at(seconds).utc.strftime('%R')
  end
end
