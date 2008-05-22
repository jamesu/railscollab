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

class TextListConfigHandler < ConfigHandler
	
	def value
		res = []
		@rawValue.each_line { |l| res << l.strip }
		return res
	end
	
	def value=(val)
		if val.class == Array:
			@rawValue = val.join("\r\n")
		else
			# Clean input
		    res = []
		    val.to_s.each_line { |l| res << l.strip }
			@rawValue = res.uniq.reject{ |el| !el.empty? }.join("\r\n")
		end
	end
	
	def render(name, options)
		text_area_tag name, @rawValue, options.merge(:class => 'short', :rows => 10, :cols => 40)
	end
end
