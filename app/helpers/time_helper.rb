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

module TimeHelper
  include ProjectHelper
  
  def task_select_list(task_list)
  	items = []
  	task_list.each do |task_list|
  		items << ['--', 0]
  		list_name = html_escape(task_list.name)
  		items += task_list.project_tasks.collect do |task|
  			["#{list_name}: #{html_escape task.text}", task.id.to_s]
  		end
  	end
  	
  	items = [['None', 0]] + items
  end

end
