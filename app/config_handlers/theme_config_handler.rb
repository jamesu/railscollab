#==
# RailsCollab
# Copyright (C) 2008 James S Urquhart
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

class ThemeConfigHandler < ConfigHandler
	def initialize
		super
		
		begin
		  @themes = Dir.entries("public/themes").reject { |theme| File.directory?(theme) }
		rescue
		  @themes = ['default']
		end
	end
	
	def value
		@rawValue
	end
	
	def value=(val)
		@rawValue = val if @themes.include?(val)
	end
	
	def render(name, options)
		opts = options_for_select(@themes, self.value)
		select_tag name, opts, options
	end
end
