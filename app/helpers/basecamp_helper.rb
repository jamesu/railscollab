#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

module BasecampHelper
  def basecamp_time(cur_time)
    return cur_time.nil? ? '' : cur_time.strftime('%Y-%m-%dT%H:%M:%SZ')
  end

  def basecamp_date(cur_date)
    return cur_date.nil? ? '' : cur_date.strftime('%Y-%m-%d')
  end
end
