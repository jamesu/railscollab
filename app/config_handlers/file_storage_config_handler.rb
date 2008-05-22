=begin
RailsCollab
-----------

Copyright (C) 2008 James S Urquhart (jamesu at gmail.com)

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

class FileStorageConfigHandler < ConfigHandler
	
	def value
		@rawValue
	end
	
	def value=(val)
		@rawValue = val unless !(['file_system', 'local_database'].include?(val))
	end
	
	def render(name, options)
		opts = options_for_select({:file_storage_file_system.l => 'file_system', 
		                              :file_storage_local_database.l => 'local_database'}, self.value)
		select_tag name, opts, options
	end
end
