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

module AccountHelper
  include AdministrationHelper

  def account_tabbed_navigation(current)
    @selected_navigation_item = current
    items = [{:id => :my_account, :url => '/account/index'}]
  end

  def account_crumbs(current)
    [{:title => :dashboard, :url => '/dashboard'},
     {:title => :account,   :url => '/account'},
     {:title => current}]
  end
end
